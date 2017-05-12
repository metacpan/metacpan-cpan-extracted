package Spica;
use strict;
use warnings;
use utf8;
our $VERSION = '0.04';

use Spica::Client;
use Spica::Receiver::Iterator;
use Spica::Types qw(
    SpecClass
    ParserClass
);
use Spica::URIMaker;

use Furl;

use Mouse;

with 'Spica::Event';

# -------------------------------------------------------------------------
# fetcher's args
# -------------------------------------------------------------------------
has host => (
    is  => 'ro',
    isa => 'Str',
);
has scheme => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http',
);
has port => (
    is  => 'ro',
    isa => 'Int|Undef',
);
has agent => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => "Spica $VERSION",
);
has default_param => (
    is         => 'ro',
    isa        => 'HashRef',
    auto_deref => 1,
    default    => sub { +{} },
);
has default_headers => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

# -------------------------------------------------------------------------
# spica behavior's args
# -------------------------------------------------------------------------
has no_throw_http_exception => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has is_suppress_object_creation => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has is_suppress_query_creation => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has spec => (
    is        => 'rw',
    isa       => SpecClass,
    coerce    => 1,
    predicate => 'has_spec',
);
has parser => (
    is      => 'rw',
    isa     => ParserClass,
    coerce  => 1,
    lazy    => 1,
    default => 'Spica::Parser::JSON',
);

# -------------------------------------------------------------------------
# auto build args
# -------------------------------------------------------------------------
has uri_builder => (
    is         => 'ro',
    isa        => 'Spica::URIMaker',
    lazy_build => 1,
);
has fetcher => (
    is         => 'rw',
    isa        => 'Furl',
    lazy_build => 1,
);

no Mouse;

# $spica->fetch($url, $param);
# $spica->fetch($client_name, $param);
# $spica->fetch($client_name, $endpoint_name, $param);
sub fetch {
    my $self = shift;

    # get client
    my $client_name = shift;
    my $client = $self->get_client($client_name);

    # parseing args
    my ($endpoint_name, $param) = (ref $_[0] && ref $_[0] eq 'HASH' ? ('default', @_) : @_);

    # get endpoint
    my $endpoint = $client->get_endpoint($endpoint_name)
        or Carp::croak("No such enpoint ${endpoint_name}.");
    my $method = $endpoint->{method};

    $self->trigger('init', ($client, $endpoint));

    # build_uri
    my $builder = sub {
        my $builder = $self->uri_builder->new_uri->create(
            path_base => $endpoint->{path},
            requires  => $endpoint->{requires}, 
            param     => +{ $self->default_param => %$param },
        );

        {
            my @codes = $client->get_filter_code('init_builder');
            $builder = $_->($client, $builder) for @codes;
        }

        if (!$self->is_suppress_query_creation && ($method eq 'GET' || $method eq 'HEAD' || $method eq 'DELETE')) {
            # `content` is not available, I will grant `path_query`.
            # make `path_query` and delete `content` params.
            $builder->create_query;
        }

        return $builder;
    }->();
    $self->trigger('uri_build', $builder);

    # execute request
    my $response = $self->execute_request($client, $method, $builder);
    $self->trigger('request', $response);

    # execute parseing
    my $data = $self->execute_parsing($client, $response);
    $self->trigger('parse', $data);

    # execute receive
    return $self->execute_receive($client, $data);
}

sub get_client {
    my ($self, $client_name) = @_;

    if ($self->has_spec) {
        return $self->spec->get_client($client_name)
            or Carp::croak("No such client ${client_name}.");
    } else {
        # Create client and endpoint.
        return Spica::Client->new(
            name     => 'default',
            endpoint => +{
                'default' => +{
                    method   => 'GET',
                    path     => $client_name,
                    requires => [],
                },
            },
        );
    }
}

sub execute_request {
    my ($self, $client, $method, $builder) = @_;

    { # XXX: deprecated block
        # hookpoint:
        #   name: `before_request`
        #   args: ($client isa 'Spica::Client', $builder isa `Spica::URIMaker`)
        $client->call_trigger('before_request' => $builder);

        my @codes = $client->get_filter_code('before_request');
        $builder = $_->($client, $builder) for @codes;
    }

    my %param = (
        method  => $method,
        url     => $builder->as_string,
        headers => $self->default_headers, # TODO: custom any header use.
    );

    if ($method eq 'POST' || $method eq 'PUT' || $method eq 'DELETE') {
        $param{content} = $builder->content || $builder->param;
    }

    return $self->fetcher->request(%param);
}

sub execute_parsing {
    my ($self, $client, $response) = @_;

    { # XXX: deprecated block
        # hookpoint:
        #   name: `after_request`
        #   args: ($client isa 'Spica::Client', $response isa `Furl::Response`)
        $client->call_trigger('after_request' => $response);

        my @codes = $client->get_filter_code('after_request');
        $response = $_->($client, $response) for @codes;
    }

    if (!$response->is_success && !$self->no_throw_http_exception) {
        # throw Exception
        Carp::croak("Invalid response. code is '@{[$response->status]}'");
    }

    return $self->parser->parse($response->content);
}

sub execute_receive {
    my ($self, $client, $data) = @_;

    if ($self->is_suppress_object_creation) {
        return $data;
    } else {
        { # XXX: deprecated block
            # hookpoint:
            #   name: `before_receive`.
            #   args: ($client isa 'Spica::Client', $data isa 'ArrayRef|HashRef')
            $client->call_trigger('before_receive' => $data);

            my @codes = $client->get_filter_code('before_receive');
            $data = $_->($client, $data) for @codes;
        }

        my $iterator = $client->receiver->new(
            data                     => $data,
            spica                    => $self,
            row_class                => $client->row_class,
            client                   => $client,
            client_name              => $client->name,
            suppress_object_creation => $self->is_suppress_object_creation,
        );

        return wantarray ? $iterator->all : $iterator;
    }
}

# -------------------------------------------------------------------------
# builders
# -------------------------------------------------------------------------
sub _build_uri_builder {
    my $self = shift;
    return Spica::URIMaker->new(
        scheme => $self->scheme,
        host   => $self->host,
        ($self->port && $self->scheme ne 'https' ? (port => $self->port) : ()),
    );
}

sub _build_fetcher {
    my $self = shift;
    return Furl->new(
        agent => $self->agent,
    );
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Spica - the HTTP client for dealing with complex WEB API.

=head1 SYNOPSIS

    my $spica = Spica->new(
        host => 'example.com',
        spec => 'Example::Spec',
    );

    my $iterator = $spica->fetch(client => 'list' => +{key => $value});

=head1 DESCRIPTION

Spica provides an interface to common WEB API many. It is the HTTP Client that combines the flexibility and scalability of a O/R Mapper and Model of Backbone.js. 

=head1 SIMPLEST CASE

create Spica's instance. arguments C<host> must be required. fetch returned object is  C<Spica::Receiver::Iterator>.

    my $spica = Spica->new(
        host => 'example.com'
    );

    my $iterator = $spica->fetch('/users', +{
        rows => 20,
    });

=head1 THE BASIC USAGE

create specifiction class.
see C<Spica::Spec> for docs on defining spec class.

    package Your::API::Spec;
    use Spica::Spec::Declare;

    client {
        name 'example';
        endpoint list => '/users' => [];
        columns qw( id name message );
    };

    1;

in your script.

    use Spica;

    my $spica = Spica->new(
        host => 'example.com',
        spec => 'Your::API::Spec',
    );

    # fetching WEB API.
    my $iterator = $spca->fetch('example', 'list', +{});

    while (my $user = $iterator->next) {
        say $user->name;
    }

=head1 ARCHITECTURE

Spica iclasses are comprised of following distinct components:

=head2 CLIENT

C<client> is a class with information about how to receipt of the request parameter data for WEB API.
C<client> uses C<Spica::Spec::Iterator> the receipt of data and GET request as the initial value, but I can cope with a wide range of API specification by extending in C<spec>.

=head2 SPEC

The C<spec> is a simple class that describes specifictions of the WEB API.
C<spec> is a simple class that describes the specifications of the WEB API. You can extend the C<client> by changing the C<receiver> class you can specify the HTTP request other than GET request.

    package Your::Spec;
    use Spica::Spec::Declare;

    client {
        name 'example';
        endpoint 'name1', '/path/to', [qw(column1 column2)];
        endpoint 'name2', '/path/to/{replace}, [qw(replace_column column)];
        endpoint 'name3', +{
            method   => 'POST',
            path     => '/path/to',
            requires => [qw(column1 column2)],
        };
        columns qw(
            column1
            column2
        );
    }

    ... and other clients ...

=head2 PARSER

C<parser> is a class for to be converted to a format that can be handled in Perl format that the API provides.
You can use an API of its own format if you extend the C<Spica::Parser>

    package Your::Parser;
    use parent qw(Spica::Parser);

    use Data::MessagePack;

    sub parser {
        my $self = shift;
        return $self->{parser} ||= Data::MessagePack->new;
    }

    sub parse {
        my ($self, $body) = @_;
        return $self->parser->unpack($body);
    }

    1;

in your script

    my $spica = Spica->new(%args);

    $spica->parser('Your::Parser');

=head2 RECEIVER

C<receiver> is a class for easier handling more data received from the WEB API.
C<receiver> This contains the C<Spica::Receiver::Row> and C<Spica::Receiver::Iterator>.

=head1 METHODS

Spica provides a number of methods to all your classes, 


=head2 $spica = Spica->new(%args)

Creates a new Spica instance.

    my $spica = Spica->new(
        host => 'example.com',
        spec => 'Your::Spec',
    );

Arguments can be:

=over

=item C<scheme>

This is the URI scheme of WEB API.
By default, C<http> is used.

=item C<host> :Str

This is the URI hostname of WEB API.
This argument is always required.

=item C<port> :Int

This is the URI port of WEB API.
By default, C<80> is used.

=item C<agent> :Str

This is the Fetcher agent name of Spica.
By default, C<Spica $VERSION> is used.

=item C<default_param> :HashRef

You can specify the parameters common to request the WEB API.

=item C<default_headers> :ArrayRef

You can specify the headers common to request the WEB API.

=item C<spec>

C<spec> expecs the name of the class that inherits C<Spiac::Spec>.
By default, C<spec> is not used.

=item C<parser>

C<parser> expects the name of the class that inherits C<Spica::Parser>.
By default, C<Spica::Parser::JSON> is used.

=item C<is_suppress_object_creation>

Specifies the receiver object creation mode. By default this value is C<false>.
If you specifies this to a C<true> value, no row object will be created when
a receive on WEB API results.

=item C<no_throw_http_exception>

Specifies the mode that does not throw the exception of HTTP. 
by default this value is C<false>.

=back

=head2 $iterator = $spica->fetch(@args);

Request to the WEB API, to build the object.
I have the interface of the following three:

=head3 $spica->fetch($client_name, $endpoint_name, $param)

It is the access method basic.

Arguments can be:

=over

=item C<client_name> : Str

Enter the name of the client that you have defined in C<spec>.

=item C<endpoint_name> : Str

Enter the name of C<endpoint> that is defined in the C<client>.

=item C<param> : HashRef

Specified in C<HashRef> the content and query parameters required to request. I will specify the HashRef empty if there are no parameters.

=back

=head3 $spica->fetch($client_name, $param)

You can omit the C<endpoint_name> of C<fetch> If you specify a string of C<default> to C<name> of <endpoint>.

Arguments can be:

=over

=item C<client_name> : Str

=item C<param> : HashRef

=back

=head3 $spica->fetch($path, $param)

You can request by specifying to fetch the <path> If you do not specify the C<spec>.

Arguments can be:

=over

=item C<path> : Str

=item C<param> : HashRef

=back

=head1 SEE ALSO

=head1 AUTHOR

mizuki_r E<lt>ry.mizuki@gmail.comE<gt>

=head1 REPOSITORY

    git clone git@github.com:rymizuki/p5-Spica.git

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, the Spica L</AUTHOR>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
