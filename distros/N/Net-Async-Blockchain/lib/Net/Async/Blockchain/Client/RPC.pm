package Net::Async::Blockchain::Client::RPC;

use strict;
use warnings;

our $VERSION = '0.004';

=head1 NAME

Net::Async::Blockchain::Client::RPC - Async RPC Client.

=head1 SYNOPSIS

Objects of this type would not normally be constructed directly.

=head1 DESCRIPTION

Centralize all asynchronous RPC calls.

=over 4

=back

=cut

no indirect;

use Future::AsyncAwait;
use Net::Async::HTTP;
use JSON::MaybeUTF8 qw(encode_json_utf8 decode_json_utf8);
use IO::Async::Notifier;

use parent qw(IO::Async::Notifier);

use constant {
    # default value for the Net::Async::HTTP stall_timeout configuration.
    DEFAULT_TIMEOUT         => 100,
    DEFAULT_MAX_CONNECTIONS => 6
};

sub endpoint     { shift->{endpoint} }
sub rpc_user     { shift->{rpc_user} }
sub rpc_password { shift->{rpc_password} }
sub timeout      { shift->{timeout} // DEFAULT_TIMEOUT }

=head2 max_connections

L<https://metacpan.org/pod/Net::Async::HTTP#max_connections_per_host-=%3E-INT>

=over 4

=back

returns the configured max_connections value or DEFAULT_MAX_CONNECTIONS

=cut

sub max_connections { shift->{max_connections} // DEFAULT_MAX_CONNECTIONS }

=head2 http_client

Create an L<Net::Async::HTTP> instance, if it is already defined just return
the object

=over 4

=back

L<Net::Async::HTTP>

=cut

sub http_client {
    my ($self) = @_;

    return $self->{http_client} //= do {
        $self->add_child(
            my $http_client = Net::Async::HTTP->new(
                decode_content           => 1,
                stall_timeout            => $self->timeout,
                timeout                  => $self->timeout,
                max_connections_per_host => $self->max_connections,
            ));

        $http_client;
    };
}

=head2 configure

Any additional configuration that is not described on L<IO::Async::Notifier>
must be included and removed here.

=over 4

=item * C<endpoint>

=item * C<timeout> connection timeout (seconds)

=item * C<rpc_user> RPC user. (optional, default: undef)

=item * C<rpc_password> RPC password. (optional, default: undef)

=back

=cut

sub configure {
    my ($self, %params) = @_;

    for my $k (qw(endpoint rpc_user rpc_password timeout max_connections)) {
        $self->{$k} = delete $params{$k} if exists $params{$k};
    }

    $self->SUPER::configure(%params);
}

=head2 _request

Use any argument as the method parameter for the client RPC call

=over 4

=item * C<method>

=item * C<params> (any parameter required by the RPC call)

=back

L<Future> - node response as decoded json

=cut

async sub _request {
    my ($self, $method, @params) = @_;

    my $obj = {
        id     => 1,
        method => $method,
        params => [@params],
    };

    # for Geth JSON-RPC spec requires the version field to be exactly "jsonrpc": "2.0"
    $obj->{jsonrpc} = $self->jsonrpc if $self->can('jsonrpc');

    my @post_params = ($self->endpoint, encode_json_utf8($obj), content_type => 'application/json');

    # for ETH based, we don't require user+password. Check to send user+password if exists.
    push @post_params, (user => $self->rpc_user)     if $self->rpc_user;
    push @post_params, (pass => $self->rpc_password) if $self->rpc_password;

    my $response = await $self->http_client->POST(@post_params);
    return decode_json_utf8($response->decoded_content)->{result};
}

1;
