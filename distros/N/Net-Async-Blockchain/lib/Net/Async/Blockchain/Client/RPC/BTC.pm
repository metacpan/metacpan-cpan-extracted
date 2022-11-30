package Net::Async::Blockchain::Client::RPC::BTC;

use strict;
use warnings;

our $VERSION = '0.001';

=head1 NAME

Net::Async::Blockchain::Client::RPC::BTC - Async BTC RPC Client.

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new();

    $loop->add(
        my $http_client = Net::Async::Blockchain::Client::RPC::BTC->new(endpoint => 'http://127.0.0.1:8332', timeout => 100, rpc_user => 'test', rpc_password => 'test')
    );

    my $response = $http_client->get_transaction('txid...')->get;

=head1 DESCRIPTION

BTC based RPC calls

=over 4

=back

=cut

no indirect;

use parent qw(Net::Async::Blockchain::Client::RPC);

=head2 get_transaction

https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/wallet/gettransaction/

=over 4

=back

L<Future>

=cut

sub get_transaction {
    my ($self, @params) = @_;
    return $self->_request('gettransaction', @params);
}

use parent qw(Net::Async::Blockchain::Client::RPC);

=head2 get_raw_transaction

https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/rawtransactions/getrawtransaction/

=over 4

=back

L<Future>

=cut

sub get_raw_transaction {
    my ($self, @params) = @_;
    return $self->_request('getrawtransaction', @params);
}

=head2 get_block

https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/wallet/getblock/

=over 4

=back

L<Future>

=cut

sub get_block {
    my ($self, @params) = @_;
    return $self->_request('getblock', @params);
}

=head2 validate_address

https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/util/validateaddress/

=over 4

=back

L<Future>

=cut

sub validate_address {
    my ($self, @params) = @_;
    return $self->_request('validateaddress', @params);
}

=head2 get_last_block

https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/blockchain/getblockcount/

=over 4

=back

L<Future>

=cut

sub get_last_block {
    my ($self) = @_;
    return $self->_request('getblockcount');
}

=head2 get_block_hash

https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/blockchain/getblockhash/

=over 4

=back

L<Future>

=cut

sub get_block_hash {
    my ($self, @params) = @_;
    return $self->_request('getblockhash', @params);
}

1;

