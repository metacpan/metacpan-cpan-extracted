use Test::More;
use lib 't/test';

use Foo;

ok(my $f = Foo::Class->new);

is($f->one, 1, 'one');
is($f->two, 2, 'two');
is($f->three, 3, 'three');
is($f->four, 4, 'four');

done_testing();
