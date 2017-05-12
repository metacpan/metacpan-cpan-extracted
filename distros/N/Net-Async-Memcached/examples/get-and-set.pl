#!/usr/bin/perl 
use strict;
use warnings;
use IO::Async::Loop;
use Net::Async::Memcached::Client;

# Create a loop first
my $loop = IO::Async::Loop->new;
my $mc;

# Connect to the memcached server
$mc = Net::Async::Memcached::Client->new(
  host    => 'localhost', # this is the default
  loop    => $loop,
  on_connected => sub {
    # When connected, set a value
    my ($k, $v) = qw(hello world);
    $mc->set(
      $k => $v,
      on_complete  => sub {
        my %args = @_;
        # And when we've confirmed it's been set, try reading a value
        print "Have stored a value for " . $args{key} . "\n";
        $mc->get(
          $k,
          on_complete  => sub {
	    # Report the value
            my %args = @_;
            print "Value stored for " . $args{key} . " was " . $args{value} . "\n";
            $loop->later(sub { $loop->loop_stop });
          },
          on_error  => sub { die "Failed because of @_\n" }
        );
      }
    );
  }
);

$loop->loop_forever;

