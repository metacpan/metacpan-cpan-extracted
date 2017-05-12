#!/usr/bin/env perl

use Test::More;

if ($^O =~ m/(?:linux|aix|macos|darwin|freebsd|netbsd)/i) {
	plan tests => 3;
} else {
	plan skip_all => 'This test requires supported UNIX platform.';
}

use bytes;
use MojoX::Run;

my $e = MojoX::Run->new();
$e->log_level('info');

# set limit to max 1 subprocess
$e->max_running(1);


# spawn first command
my $pid = $e->spawn(
    cmd => sub { sleep 5; exit 0 },
    exit_cb => sub {},
);

#print STDERR "Spawn 1st: $pid; error: ", $e->error(), "\n";
ok $pid > 0, "Spawn succeeded";

# spawn second subprocess
my $pid2 = $e->spawn(
	cmd => sub { sleep 5; exit 0 },
	exit_cb => sub {},	
);

#print STDERR "Spawn 2nd: $pid2, error: ", $e->error(), "\n";
ok $pid2 == 0, 'Sencod process was not spawned.';

# increase limit
$e->max_running(2);
my $pid3 = $e->spawn(
	cmd => sub { sleep 5; exit 0 },
	exit_cb => sub { $e->ioloop()->stop() },
);

#print STDERR "Spawn 3rd: $pid3, error: ", $e->error(), "\n";
ok $pid3 > 0, "Third process was spawned [pid3 = $pid3].";

$e->ioloop()->start();
