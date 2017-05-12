use strict;
use warnings;
use POE;
use POE::Session::YieldCC;
use Test::More tests => 6;

my $seq = 1;
POE::Session::YieldCC->create(
  inline_states => {
    _start => sub {
      ok(1, "starts up fine");
      $_[KERNEL]->yield('heavy_lifting');
    },
    heavy_lifting => sub {
      is($seq++, 1, "first");
      $_[SESSION]->yieldCC('pause');
      is($seq++, 3, "third");
    },
    pause => sub {
      my $cont = $_[ARG0];
      is($seq++, 2, "second");
      $cont->();
      is($seq++, 4, "fourth");
    },
  },
);

$poe_kernel->run();
is($seq++, 5, "last");
