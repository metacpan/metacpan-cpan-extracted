# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Solana-SPLAddress.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Solana::SPLAddress') };

my ($wallet_address,
   $token_mint_address,
   $token_program_id,
   $associated_token_address,
)
    = map { pack("H*", $_) } qw(
    aa847fcdf9577b25ff09b48597bfc1d958aa87d3f0aab7e8b312c17d6ea26287
    c6fa7af3bedbad3a3d65f36aabc97431b1bbe4c2d2f6e0e47ca60203452f5d61
    06ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9
    8c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f859
);

my $expected_token_address = "8601b82db84efead60d866626c8624897d8d8bf1ecacaebf564a6c7255565775";

my ($address, $bump) = Solana::SPLAddress::find_address([$wallet_address, $token_program_id, $token_mint_address], $associated_token_address);
is($address, $expected_token_address, "Address found");
is($bump, 255, "bump is found");


