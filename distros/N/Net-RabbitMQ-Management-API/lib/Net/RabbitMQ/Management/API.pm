package Net::RabbitMQ::Management::API;
{
  $Net::RabbitMQ::Management::API::VERSION = '0.01';
}

# ABSTRACT: Interface to the HTTP Rest API of the RabbitMQ management plugin

use Moo;

use Carp qw(croak);
use HTTP::Headers;
use HTTP::Request;
use JSON::Any;
use LWP::UserAgent;
use Net::RabbitMQ::Management::API::Result;
use URI;



has 'ua' => (
    builder => '_build_ua',
    is      => 'ro',
    lazy    => 1,
);


has 'username' => (
    is      => 'ro',
    default => sub {
        return 'guest';
    },
);


has 'password' => (
    is      => 'ro',
    default => sub {
        return 'guest';
    },
);


has 'url' => (
    is       => 'ro',
    required => 1,
    trigger  => sub {
        my ( $self, $uri ) = @_;
        $self->{url} = URI->new("$uri");
    },
);

has '_json' => (
    builder => '_build__json',
    is      => 'ro',
    lazy    => 1,
);


sub request {
    my ( $self, %args ) = @_;

    my $method = delete $args{method} || croak 'Missing mandatory key in parameters: method';
    my $path   = delete $args{path}   || croak 'Missing mandatory key in parameters: path';
    my $data   = delete $args{data};

    croak "Invalid method: $method" unless grep $_ eq $method, qw(DELETE GET PATCH POST PUT);

    my $uri      = $self->_uri_for($path);
    my $request  = $self->_request_for( $method, $uri, $data );
    my $response = $self->ua->request($request);

    return Net::RabbitMQ::Management::API::Result->new( response => $response );
}

sub _request_for {
    my ( $self, $method, $uri, $data ) = @_;

    my $headers = HTTP::Headers->new;

    my $request = HTTP::Request->new( $method, $uri, $headers );
    $request->authorization_basic( $self->username, $self->password );

    if ($data) {
        my $json = $self->_json->encode($data);
        $request->content($json);
    }

    $request->header( 'Content-Length' => length $request->content );
    $request->header( 'Content-Type'   => 'application/json' );

    return $request;
}

sub _uri_for {
    my ( $self, $path ) = @_;

    my $uri = $self->url->clone;

    $uri->path( $uri->path . $path );

    return $uri;
}

sub _build__json {
    my ($self) = @_;
    return JSON::Any->new;
}

sub _build_ua {
    my ($self) = @_;
    return LWP::UserAgent->new;
}


sub get_overview {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/overview',
    );
}


sub get_nodes {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/nodes',
    );
}


sub get_node {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/nodes/%s/', $args{name} ),
    );
}


sub get_extensions {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/extensions',
    );
}


sub get_configuration {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/all-configuration',
    );
}


sub update_configuration {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: users'       unless $args{users};
    croak 'Missing key in parameters: vhosts'      unless $args{vhosts};
    croak 'Missing key in parameters: permissions' unless $args{permissions};
    croak 'Missing key in parameters: queues'      unless $args{queues};
    croak 'Missing key in parameters: exchanges'   unless $args{exchanges};
    croak 'Missing key in parameters: bindings'    unless $args{bindings};

    return $self->request(
        method => 'POST',
        path   => '/all-configuration',
        data   => \%args,
    );
}


sub get_connections {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/connections',
    );
}


sub get_connection {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/connections/%s', $args{name} ),
    );
}


sub delete_connection {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/connections/%s', $args{name} ),
    );
}


sub get_channels {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/channels',
    );
}


sub get_channel {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/channels/%s', $args{name} ),
    );
}


sub get_exchanges {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/exchanges',
    );
}


sub get_exchanges_in_vhost {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/exchanges/%s', $args{vhost} ),
    );
}


sub get_exchange {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/exchanges/%s/%s', $args{vhost}, $args{name} ),
    );
}


sub create_exchange {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};
    croak 'Missing key in parameters: type'  unless $args{type};

    return $self->request(
        method => 'PUT',
        path   => sprintf( '/exchanges/%s/%s', delete $args{vhost}, delete $args{name} ),
        data   => \%args,
    );
}


sub delete_exchange {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/exchanges/%s/%s', $args{vhost}, $args{name} ),
    );
}


sub get_exchange_bindings_by_source {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/exchanges/%s/%s/bindings/source', $args{vhost}, $args{name} ),
    );
}


sub get_exchange_bindings_by_destination {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/exchanges/%s/%s/bindings/destination', $args{vhost}, $args{name} ),
    );
}


sub publish_exchange_message {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'             unless $args{name};
    croak 'Missing key in parameters: vhost'            unless $args{vhost};
    croak 'Missing key in parameters: properties'       unless $args{properties};
    croak 'Missing key in parameters: routing_key'      unless $args{routing_key};
    croak 'Missing key in parameters: payload'          unless $args{payload};
    croak 'Missing key in parameters: payload_encoding' unless $args{payload_encoding};

    return $self->request(
        method => 'POST',
        path   => sprintf( '/exchanges/%s/%s/publish', delete $args{vhost}, delete $args{name} ),
        data   => \%args,
    );
}


sub get_queues {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/queues',
    );
}


sub get_queues_in_vhost {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/queues/%s', $args{vhost} ),
    );
}


sub get_queue {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/queues/%s/%s', $args{vhost}, $args{name} ),
    );
}


sub create_queue {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'PUT',
        path   => sprintf( '/queues/%s/%s', delete $args{vhost}, delete $args{name} ),
        data   => \%args,
    );
}


sub delete_queue {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/queues/%s/%s', $args{vhost}, $args{name} ),
    );
}


sub get_queue_bindings {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/queues/%s/%s/bindings', $args{vhost}, $args{name} ),
    );
}


sub delete_queue_contents {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/queues/%s/%s/contents', $args{vhost}, $args{name} ),
    );
}


sub get_queue_messages {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'     unless $args{name};
    croak 'Missing key in parameters: vhost'    unless $args{vhost};
    croak 'Missing key in parameters: encoding' unless $args{encoding};
    croak 'Missing key in parameters: count'    unless defined $args{count};
    croak 'Missing key in parameters: requeue'  unless defined $args{requeue};

    return $self->request(
        method => 'POST',
        path   => sprintf( '/queues/%s/%s/get', delete $args{vhost}, delete $args{name} ),
        data   => \%args,
    );
}


sub get_bindings {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/bindings',
    );
}


sub get_bindings_in_vhost {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/bindings/%s', $args{vhost} ),
    );
}


sub get_bindings_between_exchange_and_queue {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: vhost'    unless $args{vhost};
    croak 'Missing key in parameters: exchange' unless $args{exchange};
    croak 'Missing key in parameters: queue'    unless $args{queue};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/bindings/%s/e/%s/q/%s', $args{vhost}, $args{exchange}, $args{queue} ),
    );
}


sub create_bindings_between_exchange_and_queue {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: vhost'       unless $args{vhost};
    croak 'Missing key in parameters: exchange'    unless $args{exchange};
    croak 'Missing key in parameters: queue'       unless $args{queue};

    return $self->request(
        method => 'POST',
        path   => sprintf( '/bindings/%s/e/%s/q/%s', delete $args{vhost}, delete $args{exchange}, delete $args{queue} ),
        data   => \%args,
    );
}


sub get_binding {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: vhost'    unless $args{vhost};
    croak 'Missing key in parameters: exchange' unless $args{exchange};
    croak 'Missing key in parameters: queue'    unless $args{queue};
    croak 'Missing key in parameters: name'     unless $args{name};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/bindings/%s/e/%s/q/%s/%s', $args{vhost}, $args{exchange}, $args{queue}, $args{name} ),
    );
}


sub create_binding {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: vhost'    unless $args{vhost};
    croak 'Missing key in parameters: exchange' unless $args{exchange};
    croak 'Missing key in parameters: queue'    unless $args{queue};
    croak 'Missing key in parameters: name'     unless $args{name};

    return $self->request(
        method => 'PUT',
        path   => sprintf( '/bindings/%s/e/%s/q/%s/%s', $args{vhost}, $args{exchange}, $args{queue}, $args{name} ),
    );
}


sub delete_binding {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: vhost'    unless $args{vhost};
    croak 'Missing key in parameters: exchange' unless $args{exchange};
    croak 'Missing key in parameters: queue'    unless $args{queue};
    croak 'Missing key in parameters: name'     unless $args{name};

    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/bindings/%s/e/%s/q/%s/%s', $args{vhost}, $args{exchange}, $args{queue}, $args{name} ),
    );
}


sub get_vhosts {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/vhosts',
    );
}


sub get_vhost {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/vhosts/%s', $args{name} ),
    );
}


sub create_vhost {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'PUT',
        path   => sprintf( '/vhosts/%s', $args{name} ),
    );
}


sub delete_vhost {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/vhosts/%s', $args{name} ),
    );
}


sub get_vhost_permissions {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/vhosts/%s/permissions', $args{name} ),
    );
}


sub get_users {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/users',
    );
}


sub get_user {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/users/%s', $args{name} ),
    );
}


sub create_user {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};
    croak 'Missing key in parameters: tags' unless $args{tags};
    croak 'Missing key in parameters: password or password_hash' unless $args{password} or $args{password_hash};

    return $self->request(
        method => 'PUT',
        path   => sprintf( '/users/%s', delete $args{name} ),
        data   => \%args,
    );
}


sub delete_user {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/users/%s', $args{name} ),
    );
}


sub get_user_permissions {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/users/%s/permissions', $args{name} ),
    );
}


sub get_user_details {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/whoami',
    );
}


sub get_users_permissions {
    my ($self) = @_;

    return $self->request(
        method => 'GET',
        path   => '/permissions',
    );
}


sub get_user_vhost_permissions {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/permissions/%s/%s', $args{vhost}, $args{name} ),
    );
}


sub create_user_vhost_permissions {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'      unless $args{name};
    croak 'Missing key in parameters: vhost'     unless $args{vhost};
    croak 'Missing key in parameters: write'     unless $args{write};
    croak 'Missing key in parameters: read'      unless $args{read};
    croak 'Missing key in parameters: configure' unless $args{configure};

    return $self->request(
        method => 'PUT',
        path   => sprintf( '/permissions/%s/%s', delete $args{vhost}, delete $args{name} ),
        data   => \%args,
    );
}


sub delete_user_vhost_permissions {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name'  unless $args{name};
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/permissions/%s/%s', $args{vhost}, $args{name} ),
    );
}


sub vhost_aliveness_test {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: vhost' unless $args{vhost};

    return $self->request(
        method => 'GET',
        path   => sprintf( '/aliveness-test/%s', $args{vhost} ),
    );
}

1;

__END__
=pod

=head1 NAME

Net::RabbitMQ::Management::API - Interface to the HTTP Rest API of the RabbitMQ management plugin

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Net::RabbitMQ::Management::API;
    use Data::Dumper;

    my $a = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_overview;

    # $result->content is either an arrayref or an hashref
    # depending on the API call that has been made
    printf "%s\n", Dumper $result->content;    # prints random bits of information that describe the whole system

=head1 DESCRIPTION

L<Net::RabbitMQ::Management::API> provides a set of modules to access
L<RabbitMQ|http://hg.rabbitmq.com/rabbitmq-management/raw-file/rabbitmq_v2_6_1/priv/www/api/index.html>
in an object oriented way.

B<Note:> This library has been tested against the RabbitMQ Management Plugin version 2.6.1.

=head1 ATTRIBUTES

=head2 ua

By default a L<LWP::UserAgent> object but it can be anything that
implements the same interface.

=head2 username

By default is guest. This can set the user for the API calls.

=head2 password

By default is guest. This can set the password for the API calls.

=head2 url

Url for the API calls. Is mandatory.

=head1 METHODS

=head2 request

All L<Net::RabbitMQ::Management::API> calls are using this method
for making requests to RabbitMQ. This method can be used directly.
It accepts a hash with following keys:

=over

=item *

B<method>: mandatory string, one of the following:

=over

=item *

DELETE

=item *

GET

=item *

PATCH

=item *

POST

=item *

PUT

=back

=item *

B<path>: mandatory string of the relative path used for making the
API call.

=item *

B<data>: optional data reference, usually a reference to an array
or hash. It must be possible to serialize this using L<JSON::Any>.
This will be the HTTP request body.

=back

Usually you should not end up using this method at all. It's only
available if L<Net::RabbitMQ::Management::API> is missing anything
from the RabbitMQ API. Here are some examples of how to use it:

=over

=item *

Same as L<Net::RabbitMQ::Management::API/get_overview>:

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->request(
        method => 'GET',
        path   => '/overview',
    );

=item *

Same as L<Net::RabbitMQ::Management::API/get_configuration>:

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->request(
        method => 'GET',
        path   => '/all-configuration',
    );

=back

This method always returns a L<Net::RabbitMQ::Management::API::Result> object.

=head2 get_overview

Get various random bits of information that describe the whole system.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_overview;

=head2 get_nodes

Get a list of nodes in the RabbitMQ cluster.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_nodes;

=head2 get_node

Get an individual node in the RabbitMQ cluster.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the node

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_node( name => 'foo' );

=head2 get_extensions

Get a list of extensions to the management plugin.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_extensions;

=head2 get_configuration

Get the server configuration.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_configuration;

=head2 update_configuration

Upload an existing server configuration.
This method accepts the following parameters:

=over

=item *

B<users>: mandatory arrayref of hashrefs, list of users

=item *

B<vhosts>: mandatory arrayref of hashrefs, list of vhosts

=item *

B<permissions>: mandatory arrayref of hashrefs, list of permissions

=item *

B<queues>: mandatory arrayref of hashrefs, list of queues

=item *

B<exchanges>: mandatory arrayref of hashrefs, list of exchanges

=item *

B<bindings>: mandatory arrayref of hashrefs, list of bindings

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->update_configuration(
        vhosts   => [ { 'name' => '/' } ],
        bindings => [
            {
                destination_type => 'queue',
                source           => 'bar19',
                routing_key      => 'my_routing_key',
                destination      => 'bar123',
                vhost            => '/',
                arguments        => {},
            }
        ],
        permissions => [
            {
                vhost     => '/',
                read      => '.*',
                configure => '.*',
                user      => 'guest',
                write     => '.*'
            }
        ],
        exchanges => [
            {
                vhost       => '/',
                name        => 'bar19',
                type        => 'direct',
                arguments   => {},
                auto_delete => 'false',
                durable     => 'true',
            }
        ],
        users => [
            {
                password_hash => 'Vgg+GKF7tFByrur0Z+Gaj3jjaLM=',
                name          => 'guest',
                tags          => 'administrator'
            }
        ],
        queues => [
            {
                vhost       => '/',
                name        => 'aliveness-test',
                arguments   => {},
                auto_delete => 'false',
                durable     => 'true',
            },
            {
                vhost       => '/',
                name        => 'bar123',
                arguments   => {},
                auto_delete => 'false',
                durable     => 'true',
            }
        ]
    );

=head2 get_connections

Get a list of all open connections.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_connections;

=head2 get_connection

Get an individual connection.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the connection

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_connection( name => 'foo' );

=head2 delete_connection

Close an individual connection.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the connection

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->delete_connection( name => 'foo' );

=head2 get_channels

Get a list of all open channels.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_channels;

=head2 get_channel

Get details about an individual channel.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the channel

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_channel( name => 'foo' );

=head2 get_exchanges

Get a list of all exchanges.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_exchanges;

=head2 get_exchanges_in_vhost

Get a list of all exchanges in a given virtual host.
This method accepts the following parameters:

=over

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_exchanges_in_vhost( vhost => '%2f' );

=head2 get_exchange

Get an individual exchange.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the exchange

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_exchange( name => 'bar', vhost => '%2f' );

=head2 create_exchange

Create an individual exchange.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the exchange

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<type>: mandatory string, type of the exchange

=item *

B<auto_delete>: optional boolean

=item *

B<durable>: optional boolean

=item *

B<internal>: optional boolean

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->create_exchange(
        vhost       => '%2f',
        name        => 'bar',
        type        => 'direct',
        auto_delete => 'false',
        durable     => 'true',
        internal    => 'false',
    );

=head2 delete_exchange

Delete an individual exchange.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the exchange

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->delete_exchange( name => 'bar', vhost => '%2f' );

=head2 get_exchange_bindings_by_source

Get a list of all bindings in which a given exchange is the source.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the exchange

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_exchange_bindings_by_source( name => 'bar', vhost => '%2f' );

=head2 get_exchange_bindings_by_destination

Get a list of all bindings in which a given exchange is the destination.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the exchange

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_exchange_bindings_by_destination( name => 'bar', vhost => '%2f' );

=head2 publish_exchange_message

Publish a message to a given exchange.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the exchange

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<routing_key>: mandatory string

=item *

B<payload>: mandatory string

=item *

B<payload_encoding>: mandatory string

=item *

B<properties>: mandatory hashref

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->publish_exchange_message(
        vhost            => '%2f',
        name             => 'foo',
        routing_key      => 'my_routing_key',
        payload          => 'my_body',
        payload_encoding => 'string',
        properties       => {},
    );

=head2 get_queues

Get a list of all queues.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_queues;

=head2 get_queues_in_vhost

Get a list of all queues in a given virtual host.
This method accepts the following parameters:

=over

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_queues_in_vhost( vhost => '%2f' );

=head2 get_queue

Get an individual queue.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the queue

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_queue( name => 'foo', vhost => '%2f' );

=head2 create_queue

Create an individual queue.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the queue

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<auto_delete>: optional boolean

=item *

B<durable>: optional boolean

=item *

B<node>: optional string

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->create_queue(
        name        => 'foo',
        vhost       => '%2f',
        auto_delete => 'false',
        durable     => 'true',
        node        => 'bar',
    );

=head2 delete_queue

Delete an individual queue.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the queue

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->delete_queue( name => 'foo', vhost => '%2f' );

=head2 get_queue_bindings

Get a list of all bindings on a given queue.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the queue

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_queue_bindings( name => 'foo', vhost => '%2f' );

=head2 delete_queue_contents

Delete contents of a queue.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the queue

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->delete_queue_contents( name => 'foo', vhost => '%2f' );

=head2 get_queue_messages

Get messages from a queue.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the queue

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<encoding>: mandatory string, payload encoding type

=over

=item *

auto

=item *

base64

=back

=item *

B<count>: mandatory integer, controls the number of messages to get

=item *

B<requeue>: mandatory boolean, determines whether the messages will be removed from the queue

=item *

B<truncate>: optional integer, if present, will truncate the message payload if it is larger than the size given (in bytes)

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_queue_messages(
        name     => 'foo',
        vhost    => '%2f',
        count    => 0,
        requeue  => 'true',
        truncate => 50000,
        encoding => 'auto',
    );

=head2 get_bindings

Get a list of all bindings.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_bindings;

=head2 get_bindings_in_vhost

Get a list of all bindings in a given virtual host.
This method accepts the following parameters:

=over

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_bindings_in_vhost( vhost => '%2f' );

=head2 get_bindings_between_exchange_and_queue

Get a list of all bindings between an exchange and a queue.
This method accepts the following parameters:

=over

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<exchange>: mandatory string, name of the exchange

=item *

B<queue>: mandatory string, name of the queue

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_bindings_between_exchange_and_queue( vhost => '%2f', exchange => 'foo', queue => 'bar' );

=head2 create_bindings_between_exchange_and_queue

Create a new binding between an exchange and a queue.
This method accepts the following parameters:

=over

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<exchange>: mandatory string, name of the exchange

=item *

B<queue>: mandatory string, name of the queue

=item *

B<routing_key>: optional string

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->create_bindings_between_exchange_and_queue(
        vhost       => '%2f',
        exchange    => 'foo',
        queue       => 'bar',
        routing_key => 'my_routing_key',
    );

=head2 get_binding

Get an individual binding between an exchange and a queue.
This method accepts the following parameters:

=over

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<exchange>: mandatory string, name of the exchange

=item *

B<queue>: mandatory string, name of the queue

=item *

B<name>: mandatory string, name of the binding

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_binding(
        vhost    => '%2f',
        exchange => 'bar',
        queue    => 'foo',
        name     => 'binding',
    );

=head2 create_binding

Create an individual binding between an exchange and a queue.
This method accepts the following parameters:

=over

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<exchange>: mandatory string, name of the exchange

=item *

B<queue>: mandatory string, name of the queue

=item *

B<name>: mandatory string, name of the binding

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->create_binding(
        vhost    => '%2f',
        exchange => 'bar',
        queue    => 'foo',
        name     => 'binding',
    );

=head2 delete_binding

Delete an individual binding between an exchange and a queue.
This method accepts the following parameters:

=over

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<exchange>: mandatory string, name of the exchange

=item *

B<queue>: mandatory string, name of the queue

=item *

B<name>: mandatory string, name of the binding

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->delete_binding(
        vhost    => '%2f',
        exchange => 'bar',
        queue    => 'foo',
        name     => 'binding',
    );

=head2 get_vhosts

Get a list of all vhosts.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_vhosts;

=head2 get_vhost

Get an individual virtual host.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_vhost( name => 'foo' );

=head2 create_vhost

Create an individual virtual host.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->create_vhost( name => 'foo' );

=head2 delete_vhost

Delete an individual virtual host.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->delete_vhost( name => 'foo' );

=head2 get_vhost_permissions

Get a list of all permissions for a given virtual host.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_vhost_permissions( name => 'foo' );

=head2 get_users

Get a list of all users.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_users;

=head2 get_user

Get an individual user.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the user

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_user( name => 'name' );

=head2 create_user

Create an individual user.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the user

=item *

B<tags>: mandatory string

=item *

B<password>: mandatory strings

=item *

B<password_hash>: mandatory string

=back

B<Either password or password_hash must be set.>

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->create_user(
        name          => 'name',
        password_hash => 'ISsWSv7CvZZts2lfN+TJPvUkSdo=',
        tags          => 'administrator',
    );

=head2 delete_user

Delete an individual user.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the user

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->delete_user( name => 'name' );

=head2 get_user_permissions

Get a list of all permissions for a given user.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the user

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_user_permissions( name => 'name' );

=head2 get_user_details

Get details of the currently authenticated user.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_user_details;

=head2 get_users_permissions

Get a list of all permissions for all users.
This method does not require any parameters.

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_users_permissions;

=head2 get_user_vhost_permissions

Get an individual permission of a user and virtual host.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the user

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->get_user_vhost_permissions( name => 'name', vhost => '%2f' );

=head2 create_user_vhost_permissions

Create an individual permission of a user and virtual host.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the user

=item *

B<vhost>: mandatory string, name of the vhost

=item *

B<write>: mandatory string

=item *

B<read>: mandatory string

=item *

B<configure>: mandatory string

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->create_user_vhost_permissions(
        vhost     => '%2f',
        name      => 'name',
        configure => '.*',
        write     => '.*',
        read      => '.*',
    );

=head2 delete_user_vhost_permissions

Delete an individual permission of a user and virtual host.
This method accepts the following parameters:

=over

=item *

B<name>: mandatory string, name of the user

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->delete_user_vhost_permissions(
        vhost     => '%2f',
        name      => 'name',
    );

=head2 vhost_aliveness_test

Declares a test queue, then publishes and consumes a message.
This method accepts the following parameters:

=over

=item *

B<vhost>: mandatory string, name of the vhost

=back

    my $a      = Net::RabbitMQ::Management::API->new( url => 'http://localhost:55672/api' );
    my $result = $a->vhost_aliveness_test( vhost => '%2f' );

=head1 DOCUMENTATION

The documentation has been taken directly from
L<RabbitMQ|http://hg.rabbitmq.com/rabbitmq-management/raw-file/rabbitmq_v2_6_1/priv/www/api/index.html>.
Please also read the documentation there, since it might be more complete.

=head1 AUTHOR

Ioana Budai <hurith@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ioana Budai.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

