use Types::Standard qw/Str/;
use lib 't/lib';
use Test;
use Testing;
use Tester;

use Test::More;
use Test;

my $t = Test->new();

is($t->one, 1);
is($t->two, 2);

$t = Testing->new();

is($t->one, 1);
is($t->two, 2);
is($t->three, 3);
is($t->four, 4);

$t = Tester->new();

is($t->one, 1);
is($t->two, 2);
is($t->three, 3);
is($t->four, 4);
is($t->five, 5);
is($t->six, 6);
is($t->str, 'abc');
is($t->fact('abc', 'def'), 'two strings');
is($t->fact('abc'), 'one string');
is($t->fact, 'default');

done_testing();
