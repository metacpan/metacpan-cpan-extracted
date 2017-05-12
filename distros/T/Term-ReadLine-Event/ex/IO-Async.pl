#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use IO::Async::Handle;

use Term::ReadLine 1.09;
use File::Basename;
use lib dirname($0) . '/lib';
use ExampleHelpers qw(
  initialize_completion update_time print_input
);

my $loop = IO::Async::Loop->new;
$loop->add( IO::Async::Timer::Periodic->new(
   interval => 1,
   on_tick => \&update_time,
)->start );

my $term = Term::ReadLine->new('...');
initialize_completion($term);

my $watcher;
$term->event_loop(
                  sub { 
                      # This callback is called every time T::RL wants to
                      # read something from its input.  The parameter is
                      # the return from the other callback.
                      my $ready = shift;
                      $$ready = 0;
                      $loop->loop_once while !$$ready;
                  },
                  sub {
                      # This callback is called as the T::RL is starting up
                      # readline the first time.  The parameter is the file
                      # handle that we need to monitor.  The return value
                      # is used as input to the previous callback.
                      my $fh = shift;

                      # The data for IO::Async is just the ready flag.  To
                      # ensure we're referring to the same value, this is
                      # a SCALAR ref.
                      my $ready = \ do{my $dummy};
                      $loop->add( $watcher = IO::Async::Handle->new(
                                                         read_handle => $fh,
                                                         on_read_ready => sub { $$ready = 1 },
                                                        ) );
                      $ready;
                  }
                 );

my $input = $term->readline('> ');

# clean up by removing the watcher.
$loop->remove($watcher);

print_input($input);
