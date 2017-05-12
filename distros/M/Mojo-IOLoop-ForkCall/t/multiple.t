#!/usr/bin/env perl

use Mojo::IOLoop;
use Mojo::IOLoop::ForkCall;
 
use Test::More;

# This test checks that the second child doesn't fire the first's callback
# when it resets it's ioloop. This is the "not my stream" comment in the parent's
# stream's close callback.
#
# Note that it depends on the Test::More output stream being forked into the child
# if this does not happen, it may not fail, so this test passing is not 100% proof,
# then again, failure should be an indicator of problem.

my $delay = Mojo::IOLoop->delay;
my @fc;
for my $id (1..2) {
  my $fc = Mojo::IOLoop::ForkCall->new;
  push @fc, $fc; #keep fc in scope
  my $end = $delay->begin;
  $fc->run(
    sub { return 1 },
    sub {
      my ($fc, $err, @return) = @_;
      ok ! $err;
      $end->();
    }
  );
};
 
$delay->wait;

done_testing;

