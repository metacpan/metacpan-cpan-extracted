use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::More 0.88;

{
  $@ = 'hello';
  any(123);
  is($@, 'hello', q{dynamically loaded test doesn't overwrite $@} );
}

{
  $! = 11;
  all(123);
  is( 0 + $!, 11, q{dynamically loaded test doesn't overwrite $!} );
}

{
  $^E = 11;
  re(qr{a});
  is( 0 + $^E, 11, q{dynamically loaded test doesn't overwrite $^E} );
}

{
  $@ = 'hello';
  cmp_deeply(
    'hello',
    str($@),
    'when passing $@ to str() it is not localized away from new'
  );
}

done_testing;
