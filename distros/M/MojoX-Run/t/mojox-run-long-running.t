#!/usr/bin/env perl

use Test::More;

if ($^O =~ m/(?:linux|freebsd|netbsd)/i) {
	plan tests => 2;
} else {
	plan skip_all => 'This test requires supported UNIX platform.';
}

use MojoX::Run;

my $t = 5;

my $e = MojoX::Run->new();
$e->log_level('info');

my $read_lines = 0;

# start vmstat command...
my $pid = $e->spawn(
	cmd => 'vmstat 1',
	exec_timeout => $t,
	stdout_cb => sub { $read_lines++; },
	exit_cb => sub {
		# stop ioloop
		$e->ioloop()->stop();
	},
);

# start loop
$e->ioloop()->start();

ok $pid > 0, "Spawn succeeded";
ok $read_lines >= $t, "Got input.";
