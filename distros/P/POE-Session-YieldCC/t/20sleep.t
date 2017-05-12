use strict;
use warnings;
use POE;
use POE::Session::YieldCC;
use Test::More tests => 2;

POE::Session::YieldCC->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->yield('sleepy');
      $_[KERNEL]->delay('in_between', 1);
    },
    sleepy => sub {
      my $start = time;
      $_[SESSION]->sleep(5);
      ok((time - $start) > 3, "slept for at least 3 seconds?");
      ok($_[HEAP]{in_between}, "stuff happened while we slept");
    },
    in_between => sub {
      $_[HEAP]{in_between} = 1;
    },
  },
);

$poe_kernel->run();
