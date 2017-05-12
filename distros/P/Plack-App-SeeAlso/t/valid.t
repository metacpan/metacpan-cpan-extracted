use strict;
use warnings;
use Test::More;

use Plack::App::SeeAlso qw(valid_seealso);

my @valid = (
    ["",[],[],[]],
    ["",['foo'],['bar'],['d:oz']],
    ["",['foo',''],['bar','b2'],['d:oz','http://example.org']],
    ["",['foo'],['bar'],[]], # elements may be omitted
);

is(valid_seealso($_), $_) for @valid;

my @invalid = (
    {},
    \*STDIN,
    bless (["",[],[],[]], "Foo"),
    [[],[],[],[]],
    [undef,[],[],[]],
    ["",[undef],[],[]],
    ["",[{}],[""],[""]],
);
ok (!valid_seealso $_);

done_testing;
