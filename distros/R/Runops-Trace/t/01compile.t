#!perl

use Test::More tests => 5;

use_ok('Runops::Trace');
Runops::Trace::enable_tracing();

pass('and it continues to work');
eval  { pass('... in eval {}') };
eval q{ pass('... in eval STRING') };

is( Runops::Trace::ARITY_BINARY(), 2, "constant" );
