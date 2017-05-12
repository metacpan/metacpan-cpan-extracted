#!/usr/bin/env perl

use Test::More;

if ($^O =~ m/(?:linux|freebsd|netbsd|aix|macos|darwin)/i) {
	plan tests => 4;
} else {
	plan skip_all => 'This test requires supported UNIX platform.';
}

use bytes;
use MojoX::Run;
#use Data::Dumper;

my $e = MojoX::Run->new();
$e->log_level('info');

my $cb_exit_status = undef;
my $cb_pid = undef;
my $cb_res_len = 0;

my $pid = $e->spawn(
    cmd => "sleep 1 && ls",
    exit_cb => sub {
      my ($pid, $res) = @_;
      $cb_pid = $pid;
      $cb_exit_status = $res->{exit_status};   
      $cb_res_len = length($res->{stdout});

      # stop ioloop
      $e->ioloop->stop();
    },
);

#print "OBJ: ", Dumper($e), "\n";

# start loop
$e->ioloop()->start();

print "PID: $pid; error: ", $e->error(), "\n";
ok $pid > 0, "Spawn succeeded";
ok $pid == $cb_pid, "cb_pid == pid";
ok $cb_exit_status  == 0, "cb_exit_status == 0";
ok $cb_res_len > 0, "result len > 0: $cb_res_len";