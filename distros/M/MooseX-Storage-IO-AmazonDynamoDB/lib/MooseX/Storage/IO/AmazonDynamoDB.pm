package MooseX::Storage::IO::AmazonDynamoDB;

use strict;
use 5.014;
our $VERSION = '0.06';

use Amazon::DynamoDB;
use AWS::CLI::Config;
use Data::Dumper;
use JSON::MaybeXS;
use Module::Runtime qw(use_module);
use MooseX::Role::Parameterized;
use MooseX::Storage;
use Types::Standard qw(Str HashRef HasMethods);
use Throwable::Error;
use namespace::autoclean;

parameter key_attr => (
    isa      => 'Str',
    required => 1,
);

parameter table_name => (
    isa     => 'Maybe[Str]',
    default => undef,
);

parameter table_name_method => (
    isa     => 'Str',
    default => 'dynamo_db_table_name',
);

parameter client_attr => (
    isa     => 'Str',
    default => 'dynamo_db_client',
);

parameter client_builder_method => (
    isa     => 'Str',
    default => 'build_dynamo_db_client',
);

parameter client_class => (
    isa     => 'Str',
    default => 'Amazon::DynamoDB',
);

parameter client_args_method => (
    isa     => 'Str',
    default => 'dynamo_db_client_args',
);

parameter host => (
    isa     => 'Maybe[Str]',
    default => undef,
);

parameter port => (
    isa     => 'Maybe[Int]',
    default => undef,
);

parameter ssl => (
    isa     => 'Bool',
    default => undef,
);

parameter create_table_method => (
    isa     => 'Str',
    default => 'dynamo_db_create_table',
);

parameter dynamodb_local => (
    isa     => 'Bool',
    default => 0,
);

role {
    my $p = shift;

    requires 'pack';
    requires 'unpack';

    my $client_attr           = $p->client_attr;
    my $client_builder_method = $p->client_builder_method;
    my $client_args_method    = $p->client_args_method;
    my $table_name_method     = $p->table_name_method;

    method $client_builder_method => sub {
        my $class = ref $_[0] || $_[0];
        my $client_class = $p->client_class;
        use_module($client_class);
        my $client_args  = $class->$client_args_method();
        return $client_class->new(%$client_args);
    };

    has $client_attr => (
        is      => 'ro',
        isa     => HasMethods[qw(get_item put_item)],
        lazy    => 1,
        traits  => [ 'DoNotSerialize' ],
        default => sub { shift->$client_builder_method },
    );

    method $client_args_method => sub {
        my $region = AWS::CLI::Config::region;
        my ($host, $port, $ssl);
        if ($p->dynamodb_local) {
            $host = 'localhost';
            $port = 8000;
            $ssl  = 0;
        }
        $host //= $p->host // "dynamodb.$region.amazonaws.com";
        $port //= $p->port;
        $ssl  //= $p->ssl // 1;
        return {
            access_key => AWS::CLI::Config::access_key_id,
            secret_key => AWS::CLI::Config::secret_access_key,
            host       => $host,
            port       => $port,
            ssl        => $ssl,
        };
    };

    method $table_name_method => sub {
        my $class = ref $_[0] || $_[0];
        return $p->table_name if $p->table_name;
        die "$class: no table name defined!";
    };

    method load => sub {
        my ( $class, $item_key, %args ) = @_;
        my $client = $args{dynamo_db_client} || $class->$client_builder_method;
        my $inject = $args{inject}           || {};
        my $table_name = $class->$table_name_method();

        my $unpacker = sub {
            my $packed = shift;

            return undef unless $packed;

            # Deserialize JSON values
            foreach my $key (keys %$packed) {
                my $value = $packed->{$key};
                if ($value && $value =~ /^\$json\$v(\d+)\$:(.+)$/) {
                    my ($version, $json) = ($1, $2);
                    state $coder = JSON::MaybeXS->new(
                        utf8         => 1,
                        canonical    => 1,
                        allow_nonref => 1,
                    );
                    $packed->{$key} = $coder->decode($json);
                }
            }

            return $class->unpack(
                $packed,
                inject => {
                    %$inject,
                    $client_attr => $client,
                }
            );
        };

        my $future = $client->get_item(
            $unpacker,
            TableName => $table_name,
            Key       => {
                $p->key_attr => $item_key,
            },
            ConsistentRead => 'true',
        );

        return $future->get();
    };

    method store => sub {
        my ( $self, %args ) = @_;
        my $client = $args{dynamo_db_client} || $self->$client_attr;
        my $async  = $args{async}            || 0;
        my $table_name = $self->$table_name_method();

        # Store undefs and refs as JSON
        my $packed = $self->pack;
        foreach my $key (keys %$packed) {
            my $value = $packed->{$key};
            my $store_as_json = (
                (ref $value)
                || (! defined $value)
                || (! length($value))
            );
            if ($store_as_json) {
                state $coder = JSON::MaybeXS->new(
                    utf8         => 1,
                    canonical    => 1,
                    allow_nonref => 1,
                );
                $packed->{$key} = '$json$v1$:'.$coder->encode($value);
            }
        }

        my $future = $client->put_item(
            TableName => $table_name,
            Item      => $packed,
        )->on_fail(sub {
            my ($e) = @_;
            my $message = 'An error occurred while executing put_item: ';
            if (ref $e && ref $e eq 'HASH') {
                my $submessage = $e->{Message} || $e->{message};
                if ($submessage) {
                    $message .= $submessage;
                    if ($e->{type}) {
                        $message .= ' (type '.$e->{type}.')';
                    }
                } else {
                    $message .= 'Unknown error: '.Dumper($e);
                }
            } else {
                $message .= "Unknown error: $e";
            }
            Throwable::Error->throw($message);
        });

        if ($async) {
            return $future;
        }

        $future->get();
    };

    method $p->create_table_method => sub {
        my ( $class, %args ) = @_;
        my $client = delete $args{dynamo_db_client}
                     || $class->$client_builder_method;

        my $table_name = $class->$table_name_method();
        my $key_name   = $p->key_attr;

        $client->create_table(
            TableName            => $table_name,
            AttributeDefinitions => {
                $key_name => 'S',
            },
            KeySchema            => [$key_name],
            ReadCapacityUnits    => 2,
            WriteCapacityUnits   => 2,
            %args,
        )->get();

        $client->wait_for_table_status(TableName => $table_name);
    };
};

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::Storage::IO::AmazonDynamoDB - Store and retrieve Moose objects to AWS's DynamoDB, via MooseX::Storage.

=head1 SYNOPSIS

First, configure your Moose class via a call to Storage:

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(io => [ 'AmazonDynamoDB' => {
      table_name => 'my_docs',
      key_attr   => 'doc_id',
  }]);

  has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
  has 'title'   => (is => 'rw', isa => 'Str');
  has 'body'    => (is => 'rw', isa => 'Str');
  has 'tags'    => (is => 'rw', isa => 'ArrayRef');
  has 'authors' => (is => 'rw', isa => 'HashRef');

  1;

Then create your table in DynamoDB.  You could also do this directly on AWS.

  MyDoc->dynamo_db_create_table();

Now you can store/load your class to DyanmoDB:

  use MyDoc;

  # Create a new instance of MyDoc
  my $doc = MyDoc->new(
      doc_id   => 'foo12',
      title    => 'Foo',
      body     => 'blah blah',
      tags     => [qw(horse yellow angry)],
      authors  => {
          jdoe => {
              name  => 'John Doe',
              email => 'jdoe@gmail.com',
              roles => [qw(author reader)],
          },
          bsmith => {
              name  => 'Bob Smith',
              email => 'bsmith@yahoo.com',
              roles => [qw(editor reader)],
          },
      },
  );

  # Save it to DynamoDB
  $doc->store();

  # Load the saved data into a new instance
  my $doc2 = MyDoc->load('foo12');

  # This should say 'Bob Smith'
  print $doc2->authors->{bsmith}{name};

=head1 DESCRIPTION

MooseX::Storage::IO::AmazonDynamoDB is a Moose role that provides an io layer for L<MooseX::Storage> to store/load your Moose objects to Amazon's DynamoDB NoSQL database service.

You should understand the basics of L<Moose>, L<MooseX::Storage>, and L<DynamoDB|http://aws.amazon.com/dynamodb/> before using this module.

This module uses L<Amazon::DynamoDB> as its client library to the DynamoDB service.

By default it grabs authentication credentials using the same procedure as the AWS CLI, see L<AWS::CLI::Config>.  You can customize this behavior - see L<"CLIENT CONFIGURATION">.

At a bare minimum the consuming class needs to tell this role what table to use and what field to use as a primary key - see L<"table_name"> and L<"key_attr">.

=head1 PARAMETERS

There are many parameters you can set when consuming this role that configure it in different ways.

=head2 key_attr

"key_attr" is a required parameter when consuming this role.  It specifies an attribute in your class that will provide the primary key value for storing your object to DynamoDB.  Currently only single primary keys are supported, or what DynamoDB calls "Hash Type Primary Key" (see their L<documentation|http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DataModel.html#DataModel.PrimaryKey>).  See the L<"SYNOPSIS"> for an example.

=head2 table_name

Specifies the name of the DynamoDB table to use for your objects - see the example in the L<"SYNOPSIS">.  Alternatively, you can return the table name via a class method - see L<"dynamo_db_table_name">.

=head2 dynamodb_local

Use a local DynamoDB server - see L<"DYNAMODB LOCAL">.

=head2 client_class

=head2 host

=head2 port

=head2 ssl

See L<"CLIENT CONFIGURATION">.

=head2 client_attr

=head2 table_name_method

=head2 create_table_method

=head2 client_builder_method

=head2 client_args_method

Parameters you can use if you want to rename the various attributes and methods that are added to your class by this role.

=head1 ATTRIBUTES

Following are attributes that will be added to your consuming class.

=head2 dynamo_db_client

This role adds an attribute named "dynamo_db_client" to your consuming class.  This attribute holds an instance of Amazon::DynamoDB that will be used to communicate with the DynamoDB service.  See L<"CLIENT CONFIGURATION"> for more details.

You can change this attribute's name via the client_attr parameter.

=head1 METHODS

Following are methods that will be added to your consuming class.

=head2 $obj->store([ dynamo_db_client => $client ][, async => 1])

Object method.  Stores the packed Moose object to DynamoDb.  Accepts 2 optional parameters:

=over 4

=item dynamo_db_client - Directly provide a Amazon::DynamoDB object, instead of using the dynamo_db_client attribute.

=item async - Don't wait for the operation to complete, return a Future object instead.

=back

=head2 $obj = $class->load($key, [, dynamo_db_client => $client ][, inject => { key => val, ... } ])

Class method.  Queries DynamoDB with a primary key, and returns a new Moose object built from the resulting data.  Returns undefined if they key could not be found in DyanmoDB.

The first argument is the primary key to use, and is required.

Optional parameters can be specified following the key:

=over 4

=item dynamo_db_client - Directly provide a Amazon::DynamoDB object, instead of trying to build one using the class' configuration.

=item inject - supply additional arguments to the class' new function, or override ones from the resulting data.

=back

=head2 $class->dynamo_db_create_table([, dynamo_db_client => $client ][ ReadCapacityUnits => X, ... ])

Class method.  Wrapper for L<Amazon::DynamoDB>'s create_table method, with the table name and key already setup.

Takes in dynamo_db_client as an optional parameter, all other parameters are passed to Amazon::DynamoDB.

You can change this method's name via the create_table_method parameter.

=head2 dynamo_db_table_name

A class method that will return the table name to use.  This method will be called if the L<"table_name"> parameter is not set.  So you could rewrite the Moose class in the L<"SYNOPSIS"> like this:

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(io => [ 'AmazonDynamoDB' => {
      key_attr   => 'doc_id',
  }]);

  ...

  sub dynamo_db_table_name {
      my $class = shift;
      return $ENV{DEVELOPMENT} ? 'my_docs_dev' : 'my_docs';
  }

You can change this method's name via the table_name_method parameter.

=head2 $client = $class->build_dynamo_db_client()

See L<"CLIENT CONFIGURATION">.

You can change this method's name via the client_builder_method parameter.

=head2 $args = $class->dynamo_db_client_args()

See L<"CLIENT CONFIGURATION">

You can change this method's name via the client_args_method parameter.

=head1 CLIENT CONFIGURATION

There are a handful ways to configure how this module sets up a client to talk to DynamoDB:

A) Do nothing, in which case an L<Amazon::DynamoDB> object will be automatically created for you using configuration parameters gleaned from L<AWS::CLI::Config>.

B) Pass your own L<Amazon::DynamoDB> client object at every call, e.g.

  my $client = Amazon::DynamoDB(...);
  my $obj    = MyDoc->new(...);
  $obj->store(dynamo_db_client => $client);
  my $obj2 = MyDoc->load(dynamo_db_client => $client);

C) Set some L<Amazon::DynamoDB> parameters when consuming the role.  The following are available: host, port, ssl.

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(io => [ 'AmazonDynamoDB' => {
      table_name => 'my_docs',
      key_attr   => 'doc_id',
      host       => $ENV{DYNAMODB_HOST},
      port       => $ENV{DYNAMODB_PORT},
      ssl        => $ENV{DYNAMODB_SSL},
  }]);

D) Override the dynamo_db_client_args method in your class to provide your own parameters to L<Amazon::DynamoDB>'s constructor.  Note that you can also set the client_class parameter when consuming the role if you want to pass these args to a class other than L<Amazon::DynamoDB> - this could be useful in tests.  Objects instantiated using client_class must provide the get_item and put_item methods.

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(io => [ 'AmazonDynamoDB' => {
      table_name   => 'my_docs',
      key_attr     => 'doc_id',
      client_class => $ENV{DEVELOPMENT} ? 'MyTestClass' : 'Amazon::DynamoDB',
  }]);

  sub dynamo_db_client_args {
      my $class = shift;
      return {
            access_key => 'my access key',
            secret_key => 'my secret key',
            host       => 'dynamodb.us-west-1.amazonaws.com',
            ssl        => 1,
      };
  }

E) Override the build_dynamo_db_client method in your class to provide your own client object.  The returned object must provide the get_item and put_item methods.

  package MyDoc;
  ...
  sub build_dynamo_db_client {
      my $class = shift;
      return Amazon::DynamoDB->new(
          %{ My::Config::Class->dynamo_db_config },
      );
  }

=head1 DYNAMODB LOCAL

If you're using this module, you might want to check out L<DynamoDB Local|http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tools.DynamoDBLocal.html>.  For instance, you might want your development code to hit a local server and your production code to go to Amazon.  This role has a dynamodb_local parameter you can use to make this easier.

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(io => [ 'AmazonDynamoDB' => {
      table_name     => 'my_docs',
      key_attr       => 'doc_id',
      dynamodb_local => $ENV{DEVELOPMENT} ? 1 : 0,
  }]);

Having a true value for dynamodb_local is equivalent to:

  with Storage(io => [ 'AmazonDynamoDB' => {
      ...
      host       => 'localhost',
      port       => '8000',
      ssl        => 0,
  }]);

=head1 NOTES

=head2 Strongly consistent reads

When executing load(), this module will always use strongly consistent reads when calling DynamoDB's GetItem operation.  Read about DyanmoDB's consistency model in their L<FAQ|http://aws.amazon.com/dynamodb/faqs/> to learn more.

=head2 Format level (freeze/thaw)

Note that this role does not need you to implement a 'format' level for your object, i.e freeze/thaw.  You can add one if you want it for other purposes.

=head2 How references are stored

When communicating with the AWS service, the Amazon::DynamoDB code is not handling arrayrefs correctly (they can be returned out-of-order) or hashrefs at all.  I've added a simple JSON level when encountering references - it should work seamlessly in your Perl code, but if you look up the data directly in DynamoDB you'll see complex data structures stored as JSON strings.

I'm hoping to get this fixed.

=head2 How undefs and empty strings are stored

There's a similar problem with how Amazon::DynamoDB stores undef values and empty strings:

L<https://github.com/rustyconover/Amazon-DynamoDB/issues/4>

I've worked around this issue the same way for now - via JSON encode/decode.

=head1 BUGS

See L<"How references are stored">, L<"How undefs are stored">

=head1 SEE ALSO

=over 4

=item L<Moose>

=item L<MooseX::Storage>

=item L<Amazon's DynamoDB Homepage|http://aws.amazon.com/dynamodb/>

=item L<Amazon::DynamoDB> - Perl DynamoDB client.

=item L<AWS::CLI::Config> - how configuration is done by default.

=back

=head1 AUTHOR

Steve Caldwell E<lt>scaldwell@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Steve Caldwell E<lt>scaldwell@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to L<Campus Explorer|http://www.campusexplorer.com>, who allowed me to release this code as open source.

=cut
