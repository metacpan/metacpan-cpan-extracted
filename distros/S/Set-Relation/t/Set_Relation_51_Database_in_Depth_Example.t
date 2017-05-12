# This file was initially written by Todd Hepler (thepler@employees.org).

# This is trying to use the running example data from
# "Database in Depth" by C.J. Date.

use 5.008001;
use utf8;
use strict;
use warnings;
use Carp::Always 0.01;

use Test::More 0.47;
use Test::Deep 0.106;

my $sr_class_name;
sub relation { return $sr_class_name->new( @_ ); }

use Set::Relation::V1;
$sr_class_name = 'Set::Relation::V1';
validate_sr_class();

use Set::Relation::V2;
$sr_class_name = 'Set::Relation::V2';
validate_sr_class();

done_testing();

###########################################################################

sub validate_sr_class {

####

my $db = {};

$db->{suppliers} = relation( [
        [ qw(sno sname status city  ) ], [
        [ qw(S1  Smith 20     London) ],
        [ qw(S2  Jones 10     Paris ) ],
        [ qw(S3  Blake 30     Paris ) ],
        [ qw(S4  Clark 20     London) ],
        [ qw(S5  Adams 30     Athens) ],
    ],
] );

$db->{parts} = relation( [
        [ qw(pno pname color weight city  ) ], [
        [ qw(P1  Nut   Red   12.0   London) ],
        [ qw(P2  Bolt  Green 17.0   Paris ) ],
        [ qw(P3  Screw Blue  17.0   Oslo  ) ],
        [ qw(P4  Screw Red   14.0   London) ],
        [ qw(P5  Cam   Blue  12.0   Paris ) ],
        [ qw(P6  Cog   Red   19.0   London) ],
    ],
] );

$db->{shipments} = relation( [
        [ qw(sno pno qty) ], [
        [ qw(S1  P1  300) ],
        [ qw(S1  P2  200) ],
        [ qw(S1  P3  400) ],
        [ qw(S1  P4  200) ],
        [ qw(S1  P5  100) ],
        [ qw(S1  P6  100) ],
        [ qw(S2  P1  300) ],
        [ qw(S2  P2  400) ],
        [ qw(S3  P2  200) ],
        [ qw(S4  P2  200) ],
        [ qw(S4  P4  300) ],
        [ qw(S4  P5  400) ],
    ],
] );

# shorthands for the above
my $s  = $db->{suppliers};
my $p  = $db->{parts};
my $sp = $db->{shipments};

# for testing, get the tuples in a known order
my @supplier_tuples =
    sort { $a->{sno} cmp $b->{sno} }
    @{ $s->members };

my @part_tuples =
    sort { $a->{pno} cmp $b->{pno} }
    @{ $p->members };

my @shipment_tuples =
    sort {
        $a->{sno} cmp $b->{sno} ||
        $a->{pno} cmp $b->{pno}
    }
    @{ $sp->members };

# test identity
{
    diag('is_identical');
    isa_ok( $s, $sr_class_name );
    ok( $s->is_identical($s), 'relation is === to itself' );
    ok( $s->is_identical( relation( [@supplier_tuples] ) ),
        'relation is === to relation with same members'
    );

    isa_ok( $p, $sr_class_name );
    ok( $p->is_identical($p), 'relation is === to itself' );
    ok( $p->is_identical( relation( [@part_tuples] ) ),
        'relation is === to relation with same members'
    );

    isa_ok( $sp, $sr_class_name );
    ok( $sp->is_identical($sp), 'relation is === to itself' );
    ok( $sp->is_identical( relation( [@shipment_tuples] ) ),
        'relation is === to relation with same members'
    );

    ok( !$p->is_identical($s),
        'relations of different class are not ===' );
    ok( !$s->is_identical($p),
        'relations of different class are not ===' );
    ok( !$sp->is_identical($s),
        'relations of different class are not ===' );
    ok( !$p->is_identical($sp),
        'relations of different class are not ===' );

    ok( !$s->is_identical(
            relation( [ $supplier_tuples[0] ] ) ),
        'relations of same class but different members are not ==='
    );
    ok( !$s->is_identical( relation( [] ) ),
        'relations of same class but different members are not ==='
    );
}

# test relational operators

# restriction
{
    diag('restriction');
    my $s1 = $s->restriction( sub { $_->{sno} eq 'S1' } );
    my $expect = relation( [ $supplier_tuples[0] ] );
    ok( $s1->is_identical($expect), 'restriction' );
    cmp_ok( $s1->cardinality, '==', 1, 'cardinality' );
    cmp_bag( $s1->members, $expect->members, 'same members' );
}

# projection
{
    diag('projection');
    my $expect = relation(
        [ map { { city => $_ } } qw(London Paris Athens) ] );
    my $s1 = $s->projection('city');
    ok( $s1->is_identical($expect), 'projection' );
    cmp_ok( $s1->cardinality, '==', 3, 'cardinality' );
    cmp_bag( $s1->members, $expect->members, 'same members' );
}

# rename
{
    diag('rename');
    my $map = {
        a => 'sno',
        b => 'sname',
        c => 'status',
        d => 'city',
    };
    my $s1 = $s->rename($map);
    cmp_ok( $s->cardinality, '==', $s1->cardinality,
        'same cardinality on rename' );
    my $expect = relation( [
            [ qw(a   b     c      d     ) ], [
            [ qw(S1  Smith 20     London) ],
            [ qw(S2  Jones 10     Paris ) ],
            [ qw(S3  Blake 30     Paris ) ],
            [ qw(S4  Clark 20     London) ],
            [ qw(S5  Adams 30     Athens) ],
        ],
    ]);
    ok( $expect->is_identical($s1), 'expected renamed relation' );
    cmp_bag( $s1->members, $expect->members, 'same members' );
}

# union
{
    diag('union');
    my $s1 = relation( [ @supplier_tuples[ 0, 1, 2 ] ] );
    my $s2 = relation( [ @supplier_tuples[ 1, 2, 3, 4 ] ] );
    my $s3 = $s1->union($s2);
    ok( $s->is_identical($s3), 'simple union' );
    cmp_bag( $s->members, $s3->members, 'same members' );
}

# insertion
{
    diag('insertion');
    my $inserted = {
        sno    => 'S6',
        sname  => 'Adams',
        status => 30,
        city   => 'Athens',
    };
    my $s1 = $s->insertion($inserted);
    my $expect = $s->union( relation( [$inserted] ) );
    ok( $s1->is_identical($expect), 'insertion/union' );
    cmp_bag( $s1->members, $expect->members, 'same members' );
}

# intersection
{
    diag('intersection');
    my $another = {
        sno    => 'S6',
        sname  => 'Sam',
        status => 30,
        city   => 'Paris',
    };
    my $s1 = $s->intersection(
        relation( [ @supplier_tuples[ 0, 4 ], $another ] )
    );
    my $expect = relation( [ @supplier_tuples[ 0, 4 ] ] );
    ok( $s1->is_identical($expect), 'intersection' );
    cmp_bag( $s1->members, $expect->members, 'same members' );
}

# join
{
    diag('join');
    my $j = $s->join($sp);
    cmp_ok(
        $j->cardinality,
        '==',
        scalar(@shipment_tuples),
        'cardinality of join'
    );
    my $expect = relation(
        [ [qw(sno sname status city pno qty)], [] ] );
    for my $sp (@shipment_tuples) {
        my $r = $s->restriction( sub { $_->{sno} eq $sp->{sno} } );
        ( $r->cardinality == 1 ) or die;
        my $sno = $r->members->[0];
        $expect = $expect->insertion({
            sno    => $sp->{sno},
            sname  => $sno->{sname},
            status => $sno->{status},
            city   => $sno->{city},
            pno    => $sp->{pno},
            qty    => $sp->{qty},
        });
    }
    ok( $j->is_identical($expect), 'join' );
    cmp_bag( $j->members, $expect->members, 'same members' );
}

# group
{
    diag('group');
    my $sg = $s->group( 'the_rest', [qw(sno sname status)] );
    is( $sg->degree, 2, 'degree of group' );
    is_deeply( $sg->heading, [qw(city the_rest)], 'heading of group' );
    cmp_bag( $sg->attr('city'), [qw(London Paris Athens)],
        'values for nongrouped attribute' );

    my $london = $sg->restriction( sub { $_->{city} eq 'London' } )
        ->attr('the_rest')->[0];
    my $london_expect = relation( [
            [ qw(sno sname status) ], [
            [ qw(S1  Smith 20    ) ],
            [ qw(S4  Clark 20    ) ],
        ],
    ] );
    ok( $london->is_identical($london_expect), 'grouped attribute' );

    my $paris = $sg->restriction( sub { $_->{city} eq 'Paris' } )
        ->attr('the_rest')->[0];
    my $paris_expect = relation( [
            [ qw(sno sname status ) ], [
            [ qw(S2  Jones 10     ) ],
            [ qw(S3  Blake 30     ) ],
        ],
    ] );
    ok( $paris->is_identical($paris_expect), 'grouped attribute' );

    my $athens = $sg->restriction( sub { $_->{city} eq 'Athens' } )
        ->attr('the_rest')->[0];
    my $athens_expect = relation( [
            [ qw(sno sname status ) ], [
            [ qw(S5  Adams 30     ) ],
        ],
    ] );
    ok( $athens->is_identical($athens_expect), 'grouped attribute' );
}

####

} # sub main

###########################################################################

1; # Magic true value required at end of a reusable file's code.
