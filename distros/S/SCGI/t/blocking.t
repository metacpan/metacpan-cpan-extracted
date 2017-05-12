#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket::UNIX;

my @tests;

BEGIN {
  @tests = (
    { body => '', env => {}, response => '' },
    { body => 'something more interesting', env => {HELLO => 'hi', BONJOUR => 'salut'}, response => 'yay' },
  );
}

use Test::More tests => 1 + @tests * 3;

require_ok('SCGI');

my $ready;
local $SIG{HUP} = sub {
  $ready = 1;
};

for my $test_request (1, 0) {
  $ready = 0;


  my $child_ppid = fork;
  die "cannot fork: $!" unless defined $child_ppid;

  my $other_ppid = $child_ppid || getppid;

  if (($child_ppid ? 1 : 0) == ($test_request ? 1 : 0)) {
    my $socket = IO::Socket::INET->new(
      Listen => 5,
      ReuseAddr => SO_REUSEADDR,
      LocalAddr => 'localhost:9000',
    ) or die "cannot bind to port 9000: $!";

    my $scgi = SCGI->new($socket, blocking => 1);

    local $SIG{USR1} = sub {
      $socket->close;
    };
 
    kill HUP => $other_ppid
      or die "cannot send signal to client process: $!";
  
    my $test_number = 0;

    while (my $request = $scgi->accept) {
      my $test = $tests[$test_number];
      $request->read_env;
  
      read $request->connection, my $body, $request->env->{CONTENT_LENGTH};
  
      cmp_ok($body, 'eq', $test->{body}, "test request $test_number body correct")
	if $test_request;
  
      my %env = %{$request->env};
      delete $env{SCGI};
      delete $env{CONTENT_LENGTH};
      is_deeply(\%env, $test->{env}, 'recieved corrent environment for test ' . $test_number)
        if $test_request;

      $request->connection->print($test->{response});
      $request->close;
      # don't wait for accept to return false as it creates warnings in IO::Handle
      last if ++$test_number == @tests;
    }

    if ($child_ppid) {
      wait;
    }
    else {
      exit;
    }
  }
  elsif (($child_ppid ? 1 : 0) != ($test_request ? 1 : 0)) {
  
    while (! $ready) {
      select(undef, undef, undef, 0.1);
    }
  
    for my $test_number (0..$#tests) {
      my $test = $tests[$test_number];
      my $socket = IO::Socket::INET->new(
        PeerAddr => 'localhost:9000'
      );
      my $content_length = length($test->{body});
      my $env = "CONTENT_LENGTH\0$content_length\0";
      $test->{env}->{SCGI} = 1;
      for my $key (keys %{$test->{env}}) {
        $env .= "$key\0$test->{env}->{$key}\0";
      }
      print $socket length($env) . ':' . $env . ',' . $test->{body};
      my $body = '';
      while (<$socket>) {
	$body .= $_;
      }
      cmp_ok($body, 'eq', $test->{response}, 'returned body ok for test ' . $test_number)
	unless $test_request;
      $socket->close;
    }
  
    kill USR1 => $other_ppid
      or die "cannot send signal to server process: $!";

    if ($child_ppid) {
      wait;
    }
    else {
      exit;
    }
  }
}
