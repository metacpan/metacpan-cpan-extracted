use strict;
use warnings;
use Test::More 0.98;
use Scalar::Util qw/refaddr/;
use Test::Exception;

BEGIN {
    use File::Basename qw/dirname/;
    my $dir = dirname(__FILE__);
    push(@INC, $dir);
}

use Fruits;

# equivalence
ok(Fruits->APPLE == Fruits->APPLE);
ok(Fruits->APPLE != Fruits->GRAPE);
ok(Fruits->APPLE != Fruits->BANANA);

# instance variable
is(Fruits->APPLE->name, 'Apple');
is(Fruits->APPLE->color, 'red');
is(Fruits->APPLE->price, 1.2);

# instance method
is(Fruits->APPLE->make_sentence('!'), 'Apple is red!');

# get instance
is(Fruits->get(1), Fruits->APPLE);
is(Fruits->get(2), Fruits->GRAPE);
is(Fruits->get(3), Fruits->BANANA);
is_deeply(Fruits->all, {
    1 => Fruits->APPLE,
    2 => Fruits->GRAPE,
    3 => Fruits->BANANA,
});

done_testing;
