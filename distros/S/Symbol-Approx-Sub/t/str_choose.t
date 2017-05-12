use Test::More;

use Symbol::Approx::Sub (choose => 'String::Equal');


sub aa { 'aa' }

is(a(), 'aa', 'a() calls aa()');

done_testing;
