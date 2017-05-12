#!perl

use 5.008;
use strict;
use warnings 'all';

use Test::Command 0.08 tests => 2;
use Test::More 0.94;
use Test::Requires 0.02 {
	'Getopt::Long' => 2.33,
	'Pod::Usage'   => 1.36,
};

my $send_nsca = 'bin/send_nsca';

###########################################################################
# TEST USAGE MESSAGE
subtest 'Usage statement' => sub {
	my $cmd = Test::Command->new(cmd => [$^X, $send_nsca, '--help']);

	plan tests => 14;

	$cmd->exit_is_num(0, 'Exits with 0');
	$cmd->stderr_is_eq(q{}, 'Prints nothing on stderr');
	$cmd->stdout_like(qr{Options:}, 'Has Options: tag');
	$cmd->stdout_like(qr{--help}, 'Mentions help command');
	$cmd->stdout_like(qr{--version}, 'Mentions version command');

	$cmd->stdout_like(qr{-H}, 'Mentions host command');
	$cmd->stdout_like(qr{-p}, 'Mentions port command');
	$cmd->stdout_like(qr{-to}, 'Mentions timeout command');
	$cmd->stdout_like(qr{-d}, 'Mentions delimiter command');
	$cmd->stdout_like(qr{-c}, 'Mentions conf file command');

	$cmd->stdout_like(qr{defaults? to localhost}, 'Mentions default host');
	$cmd->stdout_like(qr{defaults? to 5667}, 'Mentions default port');
	$cmd->stdout_like(qr{defaults? to 10}, 'Mentions default timeout');
	$cmd->stdout_like(qr{defaults? to tab}, 'Mentions default delimiter');
};

###########################################################################
# TEST VERSION MESSAGE
subtest 'Version statement' => sub {
	my $cmd = Test::Command->new(cmd => [$^X, $send_nsca, '--version']);

	plan tests => 3;

	$cmd->exit_is_num(0, 'Exits with 0');
	$cmd->stderr_is_eq(q{}, 'Prints nothing on stderr');

	$cmd->stdout_like(qr{$send_nsca version (?:\d+\.?)+}, 'Prints version');
};

exit 0;
