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

sub say_hello1 {
  my $name = shift;
  say qq{hello $name};
}

my $p = Parallel::Manager->new(handler => \&say_hello, workers => [1 .. 3]);
p $p->before_run(\&say_hello, "python");
p $p->after_run(\&say_hello, "perl");
p $p->before_job_run(\&say_hello, "php");
p $p->after_job_run(\&say_hello, "ruby");
p $p;

ok(
  do {
    my $ret;
    eval { $ret = $p->run; };
    $ret;
  },
  'message'
);

done_testing();

