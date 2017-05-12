#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use FindBin qw/$Bin/;

BEGIN {
    use_ok('Perlbal::Control');
}

my $ctl = Perlbal::Control->new(
    config_file => $ENV{TEST_PERLBAL_CONTROL_FILE} || [qw[ / etc conf perlbal.conf ]],
);
isa_ok($ctl, 'Perlbal::Control');

SKIP: {

skip "Please set export TEST_PERLBAL_CONTROL_FILE to continue.", 4
    unless ( $ENV{TEST_PERLBAL_CONTROL_FILE} );

skip "No perlbal installed (or at least none found), why are you testing this anyway?", 4 
    unless eval { $ctl->binary_path };

ok(!$ctl->is_server_running, '... the server process is not yet running');

$ctl->start;

diag "Wait a moment for Perlbal to start";
sleep(2);

ok($ctl->is_server_running, '... the server process is now running');

$ctl->stop;

diag "Wait a moment for Perlbal to stop";
sleep(2);

ok(!-e $ctl->pid_file, '... PID file has been removed by Perlbal');
ok(!$ctl->is_server_running, '... the server process is no longer running');

}
