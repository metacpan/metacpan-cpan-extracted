#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

if ($^O =~ m/(?:linux|freebsd|netbsd|aix|macos|darwin)/i) {
	plan tests => 2;
} else {
	plan skip_all => 'This test requires supported UNIX platform.';
}

use FindBin;
use MojoX::Run;

my $e = MojoX::Run->new();
$e->log_level('info');

my $test_cmd = $FindBin::Bin . '/stdin-test.pl';
my $cb_exit_status = undef;
my $cb_pid = undef;
my $cb_stdout = undef;

my $pid = $e->spawn(
    cmd => $test_cmd,
    
    exit_cb => sub {
      my ($pid, $res) = @_;
      $cb_pid = $pid;
      $cb_exit_status = $res->{exit_status};      
      $cb_stdout = $res->{stdout};

      # stop ioloop
      $e->ioloop->stop();
    },
);

ok $pid > 0, "Spawn succeeded";

my $data_sent = 'abcdefgh';

# write some data to stdin...
$e->stdin_write($pid, $data_sent);

# close stdin
$e->stdin_close($pid);

# start loop
$e->ioloop()->start();

# check what process got on stdin...
ok defined $cb_stdout && $data_sent eq $cb_stdout, "Sent data equals received data.";