use strict;
use warnings;

use Test::Most;

use Silki::Util ();

ok(
    Silki::Util::string_is_empty(q{}),
    'string_is_empty for q{}'
);

ok(
    Silki::Util::string_is_empty(undef),
    'string_is_empty for undef'
);

ok(
    !Silki::Util::string_is_empty('foo'),
    'string_is_empty for foo'
);

is(
    Silki::Util::english_list('x'),
    'x',
    'english_list for one item'
);

is(
    Silki::Util::english_list(qw( x y )),
    'x and y',
    'english_list for two items'
);

is(
    Silki::Util::english_list(qw( x y z )),
    'x, y, and z',
    'english_list for three items'
);

done_testing();
