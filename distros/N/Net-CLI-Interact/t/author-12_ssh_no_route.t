#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


BEGIN {
  if ($ENV{AT_HOME}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests do not work at home');
  }
}

use strict; use warnings FATAL => 'all';
use Test::More 0.88;

BEGIN { use_ok( 'Net::CLI::Interact') }

my $s = Net::CLI::Interact->new(
    transport => "SSH",
    ($^O eq 'MSWin32' ?
        (app => "$ENV{HOMEPATH}\\Desktop\\plink.exe") : () ),
    connect_options => { host => "81.21.232.221" },
    personality => "cisco",
);

# should fail
eval { $s->cmd('show clock') };
like( $@, qr/No route to host|Connection timed out|read timed-out/i, 'No Route' );

done_testing;
