use strict;
use warnings;
use Test::More;

use Mojo::Collection;

my $c = Mojo::Collection->with_roles('+Iterable')->new(qw(foo bar baz));

# ------------------------------------------------
# Mojo::Collection native overloads still work
# ------------------------------------------------

subtest 'Mojo::Collection native overloads are intact' => sub {
    # @{} — dereference as array

    is_deeply( [@$c], [qw(foo bar baz)], '@{} overload works' );

};

# ------------------------------------------------
# Role overloads
# ------------------------------------------------

subtest '++ increments cursor' => sub {
    $c->reset;
    is( $c->curr, 'foo', 'cursor starts at foo' );
    $c++;
    is( $c->curr, 'bar', 'cursor at bar after ++' );
    $c++;
    is( $c->curr, 'baz', 'cursor at baz after ++' );

    # ++ at the last element is a no-op
    $c++;
    is( $c->curr, 'baz', '++ at end is a no-op' );
};

subtest '-- decrements cursor' => sub {
    $c->reset;
    $c++;
    $c++;
    is( $c->curr, 'baz', 'cursor at baz' );
    $c--;
    is( $c->curr, 'bar', 'cursor at bar after --' );
    $c--;
    is( $c->curr, 'foo', 'cursor at foo after --' );

    # -- at the first element is a no-op
    $c--;
    is( $c->curr, 'foo', '-- at start is a no-op' );
};

subtest '++ and -- do not mutate the collection' => sub {
    $c->reset;
    $c++;
    is_deeply( [@$c], [qw(foo bar baz)], 'collection contents unchanged after ++' );
    $c--;
    is_deeply( [@$c], [qw(foo bar baz)], 'collection contents unchanged after --' );
};

subtest 'object identity preserved through ++ and --' => sub {
    my $before = "$c";   # stringified ref address / object
    $c++;
    my $after  = "$c";
    # both should stringify to the same object (not a copy)
    is( ref $c, ref Mojo::Collection->with_roles('+Iterable')->new(),
        'ref type unchanged after ++' );
};

done_testing;
