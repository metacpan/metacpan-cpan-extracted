#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict; use warnings FATAL => 'all';
use Test::More 0.88;

BEGIN { use_ok( 'Net::Appliance::Session') }

my $s = new_ok( 'Net::Appliance::Session' => [{
    transport => "SSH",
    ($^O eq 'MSWin32' ?
        (app => "$ENV{HOMEPATH}\\Desktop\\plink.exe") : () ),
    host => 'sdfeu.org',
    personality => "sdf",
    connect_options => {
        ignore_host_checks => 1,
    },
    do_paging => 0,
}]);

ok( $s->connect({
    username => 'ollyg',
    password => ($ENV{SDF_PASS} || 'letmein'),
}), 'connected' );

ok( $s->cmd('ls -la'), 'ran ls -la' );

like( $s->last_prompt, qr{\$ $}, 'command ran and prompt looks ok' );

my @out = $s->last_response;
cmp_ok( scalar @out, '==', 7, 'sensible number of lines in the command output');

done_testing;
