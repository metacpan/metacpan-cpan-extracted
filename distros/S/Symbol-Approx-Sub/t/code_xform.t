use Test::More;

use Symbol::Approx::Sub (xform => sub { map { s/[^A-Za-z]//g; $_ } @_ });

sub a_a { 'aa' }

is(aa(), 'aa', 'aa() calls a_a()');

done_testing;
