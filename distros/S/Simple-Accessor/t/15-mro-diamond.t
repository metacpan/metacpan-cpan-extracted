use strict;
use warnings;

use Test::More tests => 23;
use FindBin;
use lib "$FindBin::Bin/lib";

# ===================================================================
# Test that _all_attributes follows Perl's MRO for @ISA traversal.
# The old code used BFS (shift + push), which gives wrong attribute
# order under diamond inheritance.  The fix uses mro::get_linear_isa.
# ===================================================================

# --- Diamond inheritance: DFS order ---
#
#     GrandParent (attrs: origin)
#       /       \
#   Left          Right (attrs: side)
#  (attrs: l)   (attrs: r)
#       \       /
#        Diamond (attrs: d)
#
# Perl default DFS MRO for Diamond: Diamond -> Left -> GrandParent -> Right
# BFS (old code) would give:        Diamond -> Left -> Right -> GrandParent
#
# The difference: with DFS, GrandParent's attrs come BEFORE Right's.
# With BFS, Right's attrs come before GrandParent's.
{
    package GrandParent;
    use Simple::Accessor qw{origin};
    sub _build_origin { 'gp-default' }

    package Left;
    our @ISA = ('GrandParent');
    use Simple::Accessor qw{l};
    sub _build_l { 'left-default' }

    package Right;
    our @ISA = ('GrandParent');
    use Simple::Accessor qw{r side};
    sub _build_side { 'right' }

    package Diamond;
    our @ISA = ('Left', 'Right');
    use Simple::Accessor qw{d};

    package main;

    # basic construction with diamond attrs
    my $obj = Diamond->new(d => 'diamond', l => 'L', r => 'R', origin => 'GP', side => 'S');
    ok $obj, 'diamond inheritance: object created';
    is( $obj->d,      'diamond', 'own attr set' );
    is( $obj->l,      'L',       'Left parent attr set' );
    is( $obj->origin, 'GP',      'GrandParent attr set' );
    is( $obj->r,      'R',       'Right parent attr set' );
    is( $obj->side,   'S',       'Right second attr set' );

    # lazy builders fire from correct parents
    my $obj2 = Diamond->new(d => 'x');
    is( $obj2->l,      'left-default', 'Left builder fires' );
    is( $obj2->origin, 'gp-default',   'GrandParent builder fires' );
    is( $obj2->side,   'right',        'Right builder fires' );
}

# --- Strict constructor respects full diamond hierarchy ---
{
    package StrictDiamondGP;
    use Simple::Accessor qw{gp_attr};

    package StrictDiamondLeft;
    our @ISA = ('StrictDiamondGP');
    use Simple::Accessor qw{left_attr};

    package StrictDiamondRight;
    our @ISA = ('StrictDiamondGP');
    use Simple::Accessor qw{right_attr};

    package StrictDiamond;
    our @ISA = ('StrictDiamondLeft', 'StrictDiamondRight');
    use Simple::Accessor qw{own_attr};
    sub _strict_constructor { 1 }

    package main;

    # all attrs from diamond hierarchy should be accepted
    my $obj = StrictDiamond->new(
        own_attr   => 1,
        left_attr  => 2,
        right_attr => 3,
        gp_attr    => 4,
    );
    ok $obj, 'strict diamond: all hierarchy attrs accepted';
    is( $obj->own_attr,   1, 'own attr' );
    is( $obj->left_attr,  2, 'left parent attr' );
    is( $obj->right_attr, 3, 'right parent attr' );
    is( $obj->gp_attr,    4, 'grandparent attr' );

    # unknown attr still rejected
    eval { StrictDiamond->new(own_attr => 1, typo => 'x') };
    like( $@, qr/unknown attribute/, 'strict diamond rejects unknown attr' );
}

# --- C3 MRO: if a class uses mro 'c3', attribute order should follow C3 ---
SKIP: {
    skip 'mro pragma requires perl 5.10+', 8 unless eval { require mro; 1 };

    # C3 MRO for diamond: Diamond -> Left -> Right -> GrandParent
    # (linearized: children before shared parent)
    {
        package C3GrandParent;
        use Simple::Accessor qw{gp};
        sub _build_gp { 'c3-gp' }

        package C3Left;
        our @ISA = ('C3GrandParent');
        use Simple::Accessor qw{cl};

        package C3Right;
        our @ISA = ('C3GrandParent');
        use Simple::Accessor qw{cr};

        package C3Diamond;
        use mro 'c3';
        our @ISA = ('C3Left', 'C3Right');
        use Simple::Accessor qw{cd};

        package main;

        my $obj = C3Diamond->new(cd => 'd', cl => 'l', cr => 'r', gp => 'g');
        ok $obj, 'C3 diamond: object created';
        is( $obj->cd, 'd', 'C3 own attr' );
        is( $obj->cl, 'l', 'C3 left attr' );
        is( $obj->cr, 'r', 'C3 right attr' );
        is( $obj->gp, 'g', 'C3 grandparent attr' );

        # C3 MRO order: C3Diamond, C3Left, C3Right, C3GrandParent
        require mro;
        my $mro = mro::get_linear_isa('C3Diamond');
        is_deeply( $mro, [qw(C3Diamond C3Left C3Right C3GrandParent)],
            'C3 MRO order is correct' );

        # lazy builder from grandparent still fires
        my $obj2 = C3Diamond->new(cd => 'x');
        is( $obj2->gp, 'c3-gp', 'C3 grandparent builder fires' );

        # strict constructor would work too
        ok( C3Diamond->new(cd => 'a', cl => 'b', cr => 'c', gp => 'd'),
            'C3 diamond: all attrs accepted in constructor' );
    }
}
