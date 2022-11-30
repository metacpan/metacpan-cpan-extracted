package Net::Async::Blockchain::Client::RPC::Omni;

use strict;
use warnings;

our $VERSION = '0.001';

=head1 NAME

Net::Async::Blockchain::Client::RPC::Omni - Async Omnicore RPC Client.

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new();

    $loop->add(
        my $http_client = Net::Async::Blockchain::Client::RPC::Omni->new(endpoint => 'http://127.0.0.1:8332', timeout => 100, rpc_user => 'test', rpc_password => 'test')
    );

    my $response = $http_client->get_transaction('txid...')->get;

=head1 DESCRIPTION

Omnicore based RPC calls

=over 4

=back

=cut

no indirect;

use parent qw(Net::Async::Blockchain::Client::RPC::BTC);

=head2 get_transaction

https://github.com/OmniLayer/omnicore/blob/master/src/omnicore/doc/rpc-api.md#omni_gettransaction

=over 4

=back

L<Future>

=cut

sub get_transaction {
    my ($self, @params) = @_;
    return $self->_request('omni_gettransaction', @params);
}

=head2 get_detailed_transaction

https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/wallet/gettransaction/

=cut

sub get_detailed_transaction {
    my ($self, @params) = @_;
    return $self->_request('gettransaction', @params);
}

=head2 list_by_addresses

https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/wallet/listreceivedbyaddress/

=cut

sub list_by_addresses {
    my ($self, $address) = @_;
    return $self->_request("listreceivedbyaddress", 1, \0, \0, $address);
}

1;

