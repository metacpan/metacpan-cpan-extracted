use strict;
use warnings;
use Test::More;
use Test::Exception;
use Mojo::Collection;
use Mojo::Collection::Role::GroupBy::Util qw/pack_array unpack_array/;
use Mojo::Util qw/dumper/;

# -- single key grouping --------------------------------------------------
my $c = Mojo::Collection->new([0,"a"],[1,"b"],[2,"a"])->with_roles('+GroupBy');

is_deeply $c->group_by(1)->expand,
    Mojo::Collection->new(
        ["a", [[0,"a"],[2,"a"]]],
        ["b", [[1,"b"]]],
    ),
    "expand single key";

# -- single keys are plain scalars ----------------------------------------
my $expanded = $c->group_by(1)->expand;
is ref $expanded->[0][0], '', "single keys are plain scalars";

# -- composite key grouping -----------------------------------------------
my $c2 = Mojo::Collection->new(
    [0, 1, "x"],
    [0, 1, "y"],
    [0, 2, "x"],
    [1, 1, "x"],
)->with_roles('+GroupBy');

is_deeply $c2->group_by([0, 1])->expand,
    Mojo::Collection->new(
        [0, 1, [[0,1,"x"],[0,1,"y"]]],
        [0, 2, [[0,2,"x"]]],
        [1, 1, [[1,1,"x"]]],
    ),
    "expand composite key";

dies_ok { $c->expand } "dies on ungrouped collection";

# -- chaining -------------------------------------------------------------
my $result = $c->group_by(1)->expand->map(sub { $_->[0] });
is_deeply $result->to_array, ["a", "b"], "can chain after expand";

done_testing;
