#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub inspect { Template::Stencil::_inspect($_[0]) }

# Identical paths intern to the same path_id; distinct ones do not.
{
    my $i = inspect('{% a.b %}{% a.b %}{% a.c %}');
    my @pushes = grep { $_->{op} eq 'SOP_PUSH_PATH' } @{ $i->{ops} };
    is($pushes[0]{path_id}, $pushes[1]{path_id}, 'identical paths share id');
    isnt($pushes[0]{path_id}, $pushes[2]{path_id}, 'distinct paths differ');
    is(scalar @{ $i->{paths} }, 2, 'path table deduped');
}

# The draft test's indexed path.
{
    my $i = inspect('{% page.number[0] %}');
    my $p = $i->{paths}[0];
    is($p->{str}, 'page.number[0]', 'full path string');
    is(scalar @{ $p->{segs} }, 3, 'three segments');
    is($p->{segs}[0]{name}, 'page', 'seg 0 name');
    is($p->{segs}[1]{name}, 'number', 'seg 1 name');
    is($p->{segs}[2]{index}, 0, 'seg 2 index');
}

# Mixed and chained indices.
{
    my $p = inspect('{% a.b[0][12].c %}')->{paths}[0];
    is_deeply(
        [ map { exists $_->{index} ? $_->{index} : $_->{name} } @{ $p->{segs} } ],
        [ 'a', 'b', 0, 12, 'c' ],
        'mixed dotted/indexed segments');
}

# Compile-time PERL_HASH matches the live perl's hash function.
{
    my $p = inspect('{% alpha.beta_gamma %}')->{paths}[0];
    for my $seg (@{ $p->{segs} }) {
        is($seg->{hash}, Template::Stencil::_perl_hash($seg->{name}),
           "precomputed hash for '$seg->{name}'");
    }
}

# loop-rooted detection.
{
    my $i = inspect('{% loop.index %}{% item_loop.index %}');
    my %by = map { $_->{str} => $_ } @{ $i->{paths} };
    is($by{'loop.index'}{loop_rooted}, 1, 'loop.* flagged');
    is($by{'item_loop.index'}{loop_rooted}, 0, 'item_loop.* not flagged');
}

# Segment cap.
{
    eval { inspect('{% a.b.c.d.e.f.g.h.i %}') };
    like($@, qr/more than 8 segments/, '9 segments rejected');
    ok(eval { inspect('{% a.b.c.d.e.f.g.h %}'); 1 }, '8 segments fine');
}

# Path cannot start with an index (as a statement it is not a word, so
# the tag-level error fires first; the path-level rule guards elsewhere).
{
    eval { inspect('{% [0] %}') };
    like($@, qr/expected a name or keyword/, 'leading index rejected');
}

done_testing;
