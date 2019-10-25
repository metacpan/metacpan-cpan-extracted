#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.002

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Sah/Schema/cryptocurrency.pm','lib/Sah/Schema/cryptocurrency/code.pm','lib/Sah/Schema/cryptocurrency/code_or_name.pm','lib/Sah/Schema/cryptocurrency/safename.pm','lib/Sah/Schema/cryptoexchange.pm','lib/Sah/Schema/cryptoexchange/code.pm','lib/Sah/Schema/cryptoexchange/currency_pair.pm','lib/Sah/Schema/cryptoexchange/name.pm','lib/Sah/Schema/cryptoexchange/safename.pm','lib/Sah/Schema/fiat_currency.pm','lib/Sah/Schema/fiat_or_cryptocurrency.pm','lib/Sah/SchemaR/cryptocurrency.pm','lib/Sah/SchemaR/cryptocurrency/code.pm','lib/Sah/SchemaR/cryptocurrency/code_or_name.pm','lib/Sah/SchemaR/cryptocurrency/safename.pm','lib/Sah/SchemaR/cryptoexchange.pm','lib/Sah/SchemaR/cryptoexchange/code.pm','lib/Sah/SchemaR/cryptoexchange/currency_pair.pm','lib/Sah/SchemaR/cryptoexchange/name.pm','lib/Sah/SchemaR/cryptoexchange/safename.pm','lib/Sah/SchemaR/fiat_currency.pm','lib/Sah/SchemaR/fiat_or_cryptocurrency.pm','lib/Sah/Schemas/CryptoCurrency.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
