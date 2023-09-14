package Net::Async::Blockchain::Client::RPC::BTC;

use strict;
use warnings;

our $VERSION = '0.003';

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

https://bitcoincore.org/en/doc/24.0.0/rpc/wallet/gettransaction/

=over 4

=item * C<txid> The transaction id

=item * C<include_watchonly> default=true for watch-only wallets, otherwise false

=item * C<verbose> Whether to include a `decoded` field containing the decoded transaction

=back

L<Future> - detailed information about in-wallet transaction C<txid>

=cut

sub get_transaction {
    my ($self, @params) = @_;
    return $self->_request('gettransaction', @params);
}

use parent qw(Net::Async::Blockchain::Client::RPC);

=head2 get_raw_transaction

https://bitcoincore.org/en/doc/24.0.0/rpc/rawtransactions/getrawtransaction/

=over 4

=item * C<txid> The transaction id

=item * C<verbose> If false, return a string, otherwise return a json object

=item * C<blockhash> The block in which to look for the transaction

=back

L<Future> - raw transaction data

=cut

sub get_raw_transaction {
    my ($self, @params) = @_;
    return $self->_request('getrawtransaction', @params);
}

=head2 get_block

https://bitcoincore.org/en/doc/24.0.0/rpc/wallet/getblock/

=over 4

=item * C<blockhash> the block hash

=item * C<verbosity> 0 for hex-encoded data, 1 for a JSON object, 2 for JSON object with transaction data, and 3 for JSON object with transaction data including prevout information for inputs

=back

L<Future> - string based in the verbosity value

=cut

sub get_block {
    my ($self, @params) = @_;
    return $self->_request('getblock', @params);
}

=head2 validate_address

https://bitcoincore.org/en/doc/24.0.0/rpc/util/validateaddress/

=over 4

=item * C<address> - the bitcoin address to validate

=back

L<Future> - json {isvalid  : true|false, ...}

=cut

sub validate_address {
    my ($self, @params) = @_;
    return $self->_request('validateaddress', @params);
}

=head2 get_last_block

https://bitcoincore.org/en/doc/24.0.0/rpc/blockchain/getblockcount/

=over 4

=back

L<Future> - The current block count

=cut

sub get_last_block {
    my ($self) = @_;
    return $self->_request('getblockcount');
}

=head2 get_block_hash

https://bitcoincore.org/en/doc/24.0.0/rpc/blockchain/getblockhash/

=over 4

=item * C<height> the height index

=back

L<Future> - string block hash

=cut

sub get_block_hash {
    my ($self, @params) = @_;
    return $self->_request('getblockhash', @params);
}

=head2 list_by_addresses

https://bitcoincore.org/en/doc/24.0.0/rpc/wallet/listreceivedbyaddress/

=over 4

=item * C<address> address to return the received transactions

=back

L<Future> - json containing the received transaction details

=cut

sub list_by_addresses {
    my ($self, $address) = @_;
    return $self->_request("listreceivedbyaddress", 1, \0, \0, $address);
}

=head2 get_balances

https://bitcoincore.org/en/doc/24.0.0/rpc/wallet/getbalances/

=over 4

=back

L<Future> - json object with all balances in BTC

=cut

sub get_balances {
    my ($self, @params) = @_;
    return $self->_request('getbalances', @params);
}

1;
