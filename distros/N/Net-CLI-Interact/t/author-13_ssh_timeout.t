#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict; use warnings FATAL => 'all';
use Test::More 0.88;

BEGIN { use_ok( 'Net::CLI::Interact') }

my $s = Net::CLI::Interact->new(
    transport => "SSH",
    ($^O eq 'MSWin32' ?
        (app => "$ENV{HOMEPATH}\\Desktop\\plink.exe") : () ),
    connect_options => {
        host => "route-server.bb.pipex.net",
        opts => [qw/-o ConnectTimeout=4/],
    },
    personality => "cisco",

);

# should fail
eval { $s->cmd('show clock') };
like( $@, qr/Connection timed out/, 'Timed Out' );

done_testing;
