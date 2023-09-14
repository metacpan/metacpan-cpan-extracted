package Net::Async::Blockchain::Client::RPC::Omni;

use strict;
use warnings;

our $VERSION = '0.003';

=head1 NAME

Net::Async::Blockchain::Client::RPC::Omni - Async Omnicore RPC Client.

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new();

    $loop->add(
        my $http_client = Net::Async::Blockchain::Client::RPC::Omni->new(endpoint => 'http://127.0.0.1:8332', timeout => 100, rpc_user => 'test', rpc_password => 'test')
    );

    my $response = $http_client->get_omni_transaction('txid...')->get;

=head1 DESCRIPTION

Omnicore based RPC calls

=over 4

=back

=cut

no indirect;

use parent qw(Net::Async::Blockchain::Client::RPC::BTC);

=head2 get_omni_transaction

https://github.com/omnilayer/omnicore/blob/master/src/omnicore/doc/rpc-api.md#omni_gettransaction

=over 4

=item * C<txid> the hash of the transaction to lookup

=back

L<Future> - detailed information about an Omni transaction

=cut

sub get_omni_transaction {
    my ($self, @params) = @_;
    return $self->_request('omni_gettransaction', @params);
}

=head2 omni_getwalletbalances

https://github.com/OmniLayer/omnicore/blob/master/src/omnicore/doc/rpc-api.md#omni_getwalletbalances

=over 4

=item * C<includewatchonly> include balances of watchonly addresses (default: false)

=back

L<Future> - list of the total token balances of the whole wallet.

=cut

sub get_omni_wallet_balances {
    my ($self, @params) = @_;
    return $self->_request('omni_getwalletbalances', @params);
}

1;
