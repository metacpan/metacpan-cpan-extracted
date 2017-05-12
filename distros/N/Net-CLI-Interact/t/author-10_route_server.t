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
    transport => "Telnet",
    ($^O eq 'MSWin32' ?
        (app => "$ENV{HOMEPATH}\\Desktop\\plink.exe") : () ),
    connect_options => { host => "route-server.bb.pipex.net" },
    personality => "cisco",
    timeout => 5,
);

ok( $s->cmd('show ip bgp 163.1.0.0/16'), 'ran show ip bgp 163.1.0.0/16' );

like( $s->last_prompt, qr/\w+ ?>$/, 'command ran and prompt looks ok' );

my @out = $s->last_response;
cmp_ok( scalar @out, '==', 15, 'sensible number of lines in the command output');

done_testing;
