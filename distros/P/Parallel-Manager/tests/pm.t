#!/usr/bin/perl

use 5.016;
use warnings;
use Data::Printer;
use Test::More;

use Parallel::Manager;

sub say_hello {
  my $name = shift;
  say qq{hello $name};
}

my $p = Parallel::Manager->new(handler => \&say_hello, workers => [1 .. 100]);

ok(
  do {
    my $ret;
    eval { $ret = $p->run; };
    $ret;
  },
  'message'
);

done_testing();

