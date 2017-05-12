use Test::More;

use Symbol::Approx::Sub (xform => 'Text::Metaphone');


sub a_a { 'aa' }

is(aa(), 'aa', 'aa() calls a_a()');

done_testing;
