#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use FindBin qw/$Bin/;

BEGIN {
    use_ok('Sphinx::Control');
}

my $ctl = Sphinx::Control->new(
    config_file => $ENV{TEST_SPHINX_CONTROL_FILE} || [qw[ / etc conf sphinx.conf ]],
);
isa_ok($ctl, 'Sphinx::Control');

SKIP: {

skip "Please set export TEST_SPHINX_CONTROL_FILE to continue.", 11
    unless ( $ENV{TEST_SPHINX_CONTROL_FILE} );

skip "No Sphinx installed (or at least none found), why are you testing this anyway?", 11 
    unless eval { $ctl->binary_path };

ok(!$ctl->is_server_running, '... the server process is not yet running');

$ctl->start;

diag "Wait a moment for Sphinx to start";
sleep(2);

ok($ctl->is_server_running, '... the server process is now running');

$ctl->stop;

diag "Wait a moment for Sphinx to stop";
sleep(2);

ok(!-e $ctl->pid_file, '... PID file has been removed by Sphinx');
ok(!$ctl->is_server_running, '... the server process is no longer running');

$ctl->restart;

diag "Wait a moment for Sphinx to restart";
sleep(2);

ok($ctl->is_server_running, '... the server process is now running');

$ctl->stop;

diag "Wait a moment for Sphinx to stop";
sleep(2);

ok(!-e $ctl->pid_file, '... PID file has been removed by Sphinx');
ok(!$ctl->is_server_running, '... the server process is no longer running');

$ctl->reload;

diag "Wait a moment for Sphinx to reload";
sleep(2);

ok($ctl->is_server_running, '... the server process is now running');

$ctl->stop;

diag "Wait a moment for Sphinx to stop";
sleep(2);

ok(!-e $ctl->pid_file, '... PID file has been removed by Sphinx');
ok(!$ctl->is_server_running, '... the server process is no longer running');

eval { $ctl->run_indexer('--all'); };
is($@, '', 'no error');

}
