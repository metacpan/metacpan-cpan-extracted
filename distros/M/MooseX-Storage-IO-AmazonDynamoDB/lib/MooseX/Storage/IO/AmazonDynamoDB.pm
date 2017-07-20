package MooseX::Storage::IO::AmazonDynamoDB;

use strict;
use 5.014;
our $VERSION = '0.07';

use Data::Dumper;
use JSON::MaybeXS;
use MooseX::Role::Parameterized;
use MooseX::Storage;
use PawsX::DynamoDB::DocumentClient;
use Types::Standard qw(HasMethods);
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

parameter document_client_attribute_name => (
    isa     => 'Str',
    default => 'dynamodb_document_client',
);

parameter document_client_builder => (
    isa     => 'CodeRef',
    default => sub { sub { PawsX::DynamoDB::DocumentClient->new() } },
);

role {
    my $p = shift;

    requires 'pack';
    requires 'unpack';

    my $table_name_method = $p->table_name_method;
    my $client_attr       = $p->document_client_attribute_name;
    my $client_builder    = $p->document_client_builder;

    has $client_attr => (
        is      => 'ro',
        isa     => HasMethods[qw(get put)],
        lazy    => 1,
        traits  => [ 'DoNotSerialize' ],
        default => $client_builder,
    );

    method $table_name_method => sub {
        my $class = ref $_[0] || $_[0];
        return $p->table_name if $p->table_name;
        die "$class: no table name defined!";
    };

    method load => sub {
        my ( $class, $item_key, %args ) = @_;
        my $client = $args{dynamodb_document_client} || $client_builder->();
        my $inject = $args{inject}                   || {};
        my $table_name = $class->$table_name_method();

        my $packed = $client->get(
            TableName => $table_name,
            Key => {
                $p->key_attr => $item_key,
            },
            ConsistentRead => 1,
        );

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

    method store => sub {
        my ( $self ) = @_;
        my $client = $self->$client_attr;
        my $table_name = $self->$table_name_method();
        my $packed = $self->pack;
        $client->put(
            TableName => $table_name,
            Item => $packed,
        );
    };
};

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::Storage::IO::AmazonDynamoDB - Store and retrieve Moose objects to AWS's DynamoDB, via MooseX::Storage.

=head1 SYNOPSIS

First, create a table in DynamoDB. Currently only single-keyed tables are supported.

  aws dynamodb create-table \
    --table-name my_docs \
    --key-schema "AttributeName=doc_id,KeyType=HASH" \
    --attribute-definitions "AttributeName=doc_id,AttributeType=S" \
    --provisioned-throughput "ReadCapacityUnits=2,WriteCapacityUnits=2"

Then, configure your Moose class via a call to Storage:

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

This module uses L<Paws> as its client library to the DynamoDB service, via L<PawsX::DynamoDB::DocumentClient>. By default it uses the Paws configuration defaults (region, credentials, etc.). You can customize this behavior - see L<"CLIENT CONFIGURATION">.

At a bare minimum the consuming class needs to tell this role what table to use and what field to use as a primary key - see L<"table_name"> and L<"key_attr">.

=head2 BREAKING CHANGES IN v0.07

v0.07 transitioned the underlying DynamoDB client from L<Amazon::DynamoDB> to L<Paws::Dynamodb>, in order to stay more up-to-date with AWS features. Any existing code which customized the client configuration will break when upgrading to v0.07. Support for creating tables was also removed.

The following role parameters were removed: client_attr, client_builder_method, client_class, client_args_method, host, port, ssl, dynamodb_local, create_table_method.

The following attibutes were removed: dynamo_db_client

The following methods were removed: build_dynamo_db_client, dynamo_db_client_args, dynamo_db_create_table

The dynamo_db_client parameter to load() was removed, in favor of dynamodb_document_client.

The dynamo_db_client and async parameters to store() were removed.

Please see See L<"CLIENT CONFIGURATION"> for details on how to configure your client in v0.07 and above.

=head1 PARAMETERS

There are many parameters you can set when consuming this role that configure it in different ways.

=head2 REQUIRED

=head3 key_attr

"key_attr" is a required parameter when consuming this role.  It specifies an attribute in your class that will provide the primary key value for storing your object to DynamoDB.  Currently only single primary keys are supported, or what DynamoDB calls "Hash Type Primary Key" (see their L<documentation|http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DataModel.html#DataModel.PrimaryKey>).  See the L<"SYNOPSIS"> for an example.

=head2 OPTIONAL

=head3 table_name

Specifies the name of the DynamoDB table to use for your objects - see the example in the L<"SYNOPSIS">.  Alternatively, you can return the table name via a class method - see L<"dynamo_db_table_name">.

=head3 table_name_method

By default, this role will add a method named 'dynamo_db_table_name' to your class (see below for method description). If you want to use a different name for this method (e.g., because it conflicts with an existing method), you can change it via this parameter.

=head3 document_client_attribute_name

By default, this role adds an attribute to your class named 'dynamodb_document_client' (see below for attribute description). If you want to use a different name for this attribute, you can change it via this parameter.

=head3 parameter document_client_builder

Allows customization of the PawsX::DynamoDB::DocumentClient object used to interact with DynamoDB. See L<"CLIENT CONFIGURATION"> for more details.

=head1 ATTRIBUTES

=head2 dynamodb_document_client

This role adds an attribute named "dynamodb_document_client" to your consuming class.  This attribute holds an instance of L<PawsX::DynamoDB::DocumentClient> that will be used to communicate with the DynamoDB service.

You can change this attribute's name via the document_client_attribute_name parameter.

The attribute is lazily built via document_client_builder. See L<"CLIENT CONFIGURATION"> for more details.

=head1 METHODS

Following are methods that will be added to your consuming class.

=head2 $obj->store()

Object method.  Stores the packed Moose object to DynamoDb.

=head2 $obj = $class->load($key, [, dynamodb_document_client => $client ][, inject => { key => val, ... } ])

Class method.  Queries DynamoDB with a primary key, and returns a new Moose object built from the resulting data.  Returns undefined if they key could not be found in DyanmoDB.

The first argument is the primary key to use, and is required.

Optional parameters can be specified following the key:

=over 4

=item dynamodb_document_client - Directly provide a PawsX::DynamoDB::DocumentClient object, instead of trying to build one using the class' configuration.

=item inject - supply additional arguments to the class' new function, or override ones from the resulting data.

=back

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

=head1 CLIENT CONFIGURATION

This role uses the 'dynamodb_document_client' attribute (assuming you didn't rename it via 'document_client_attribute_name') to interact with DynamoDB. This attribute is lazily built, and should hold an instance of L<PawsX::DynamoDB::DocumentClient>.

The client is built by a coderef that is stored in the role's document_client_builder parameter. By default, that coderef is simply:

  sub { return PawsX::DynamoDB::DocumentClient->new(); }

If you need to customize the client, you do so by providing your own builder coderef. For instance, you could set the region directly:

  package MyDoc;
  use Moose;
  use MooseX::Storage;
  use PawsX::DynamoDB::DocumentClient;

  with Storage(io => [ 'AmazonDynamoDB' => {
      table_name              => 'my_docs',
      key_attr                => 'doc_id',
      document_client_builder => \&_build_document_client,
  }]);

  sub _build_document_client {
      my $region = get_my_region_somehow();
      return PawsX::DynamoDB::DocumentClient->new(region => $region);
  }

See L<"DYNAMODB LOCAL"> for an example of configuring our Paws client to run against a locally running dynamodb clone.

Note: the dynamodb_document_client attribute is not typed to a strict isa('PawsX::DynamoDB::DocumentClient'), but instead requires an object that has a 'get' and 'put' method. So you can provide some kind of mocked object, but that is left as an exercise to the reader - although examples are welcome!

=head1 DYNAMODB LOCAL

Here's an example of configuring your client to run against DynamoDB Local based on an environment variable. Make sure you've read L<CLIENT CONFIGURATION>. More information about DynamoDB Local can be found at L<AWS|http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html>.

  package MyDoc;
  use Moose;
  use MooseX::Storage;
  use Paws;
  use Paws::Credential::Explicit;
  use PawsX::DynamoDB::DocumentClient;

  with Storage(io => [ 'AmazonDynamoDB' => {
      table_name              => $table_name,
      key_attr                => 'doc_id',
      document_client_builder => \&_build_document_client,
  }]);

  sub _build_document_client {
      if ($ENV{DYNAMODB_LOCAL}) {
          my $dynamodb = Paws->service(
              'DynamoDB',
              region       => 'us-east-1',
              region_rules => [ { uri => 'http://localhost:8000'} ],
              credentials  => Paws::Credential::Explicit->new(
                  access_key => 'XXXXXXXXX',
                  secret_key => 'YYYYYYYYY',
              ),
              max_attempts => 2,
          );
          return PawsX::DynamoDB::DocumentClient->new(dynamodb => $dynamodb);
      }
      return PawsX::DynamoDB::DocumentClient->new();
  }

=head1 NOTES

=head2 Strongly consistent reads

When executing load(), this module will always use strongly consistent reads when calling DynamoDB's GetItem operation.  Read about DyanmoDB's consistency model in their L<FAQ|http://aws.amazon.com/dynamodb/faqs/> to learn more.

=head2 Format level (freeze/thaw)

Note that this role does not need you to implement a 'format' level for your object, i.e freeze/thaw.  You can add one if you want it for other purposes.

=head2 Pre-v0.07 objects

Before v0.07, this module stored objects to DyanmoDB using L<Amazon::DynamoDB>. It worked around some issues with that module by serializing certain data types to JSON. Objects stored using this old system will be deserialized correctly.

=head1 SEE ALSO

=over 4

=item L<Moose>

=item L<MooseX::Storage>

=item L<Amazon's DynamoDB Homepage|http://aws.amazon.com/dynamodb/>

=item L<PawsX::DynamoDB::DocumentClient> - DynamoDB client.

=item L<Paws> - AWS library.

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
