#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Data/Sah/Filter/perl/Finance/SE/IDX/check_stock_code_listed.pm','lib/Sah/Schema/idx/listed_stock_code.pm','lib/Sah/Schema/idx/stock_code.pm','lib/Sah/SchemaR/idx/listed_stock_code.pm','lib/Sah/SchemaR/idx/stock_code.pm','lib/Sah/Schemas/Finance/SE/IDX.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
