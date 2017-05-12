#!/usr/bin/env perl

use Mojo::Base -strict;
use Mojo::IOLoop;
use Mojo::IOLoop::ForkCall qw/fork_call/;

Mojo::IOLoop->recurring( 1 => sub { say 'tick' } );

fork_call { sleep 20; return 'Some', ['Items'] } sub {
  die $@ if $@;
  use Data::Dumper;
  print Dumper \@_;
  Mojo::IOLoop->stop;
};

Mojo::IOLoop->start;

