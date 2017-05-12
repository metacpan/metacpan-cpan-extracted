use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

use POEx::ZMQ::FFI::Callable;

{ package MockFFI; use strict; use warnings;
  sub new { bless [], shift }
  sub call { 1 }
}

my $cl = POEx::ZMQ::FFI::Callable->new(
  funcA => MockFFI->new,
  funcB => MockFFI->new,
);

can_ok $cl, 'funcA', 'funcB';

ok !$cl->can('foobarbaz'), 'negative can ok';

ok $cl->funcA, 'callable funcs ok (1)';
ok $cl->funcB, 'callable funcs ok (2)';

my $methods = [ $cl->METHODS ];
ok $methods->has_any(sub { $_ eq 'funcA' })
   && $methods->has_any(sub { $_ eq 'funcB' })
   && $methods->count == 2,
   'METHODS ok' or diag explain $methods;

my $funcA = $cl->FETCH('funcA');
ok $funcA->call, 'FETCH ok';

is_deeply
  [ sort keys %{ $cl->EXPORT } ],
  [ 'funcA', 'funcB' ],
  'EXPORT ok';

done_testing
