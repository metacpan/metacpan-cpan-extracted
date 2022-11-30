package Net::Async::Blockchain::Client::RPC::ETH;

use strict;
use warnings;

our $VERSION = '0.001';

=head1 NAME

Net::Async::Blockchain::Client::RPC::ETH - Async ETH RPC Client.

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new();

    $loop->add(
        my $http_client = Net::Async::Blockchain::Client::RPC::ETH->new(endpoint => 'http://127.0.0.1:8545', timeout => 100)
    );

    my $response = $http_client->accounts()->get;

=head1 DESCRIPTION

ETH RPC calls

=over 4

=back

=cut

no indirect;

use parent qw(Net::Async::Blockchain::Client::RPC);

=head2 call

https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_call

=over 4

=back

L<Future>

=cut

sub call {
    my ($self, @params) = @_;
    return $self->_request('eth_call', @params);
}

=head2 get_transaction_receipt

https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionreceipt

=over 4

=back

L<Future>

=cut

sub get_transaction_receipt {
    my ($self, @params) = @_;
    return $self->_request('eth_getTransactionReceipt', @params);
}

=head2 accounts

https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_accounts

=over 4

=back

L<Future>

=cut

sub accounts {
    my ($self) = @_;
    return $self->_request('eth_accounts');
}

=head2 get_block_by_hash

https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getblockbyhash

=over 4

=back

L<Future>

=cut

sub get_block_by_hash {
    my ($self, @params) = @_;
    return $self->_request('eth_getBlockByHash', @params);
}

=head2 get_block_by_number

https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getblockbynumber

=over 4

=back

L<Future>

=cut

sub get_block_by_number {
    my ($self, @params) = @_;
    return $self->_request('eth_getBlockByNumber', @params);
}

=head2 get_last_block

https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_blocknumber

=over 4

=back

L<Future>

=cut

sub get_last_block {
    my ($self) = @_;
    return $self->_request('eth_blockNumber');
}

=head2 get_balance

https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getbalance

=over 4

=back

L<Future>

=cut

sub get_balance {
    my ($self, $address) = @_;
    return $self->_request('eth_getBalance', $address, 'latest');
}

1;

