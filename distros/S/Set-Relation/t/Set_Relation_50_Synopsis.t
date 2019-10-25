use 5.008000;
use utf8;
use strict;
use warnings;
use Carp::Always 0.01;

use Test::More 0.92;

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

my $r1 = relation( [ [ 'x', 'y' ], [
    [ 4, 7 ],
    [ 3, 2 ],
] ] );
pass( 'no death from instantiating $r1 w ordered-attrs format members' );
isa_ok( $r1, $sr_class_name );

my $got_r1_as_nfmt_perl = $r1->members();
pass( 'no death from extract $r1 members in named-attrs format' );
isa_ok( $got_r1_as_nfmt_perl, 'ARRAY' );
$got_r1_as_nfmt_perl = [sort {
        $a->{'x'} <=> $b->{'x'} || $a->{'y'} <=> $b->{'y'}
    } @{$got_r1_as_nfmt_perl}];
my $exp_r1_as_nfmt_perl = [
    { 'x' => 3, 'y' => 2 },
    { 'x' => 4, 'y' => 7 },
];
is_deeply( $got_r1_as_nfmt_perl, $exp_r1_as_nfmt_perl, q{$r1n val corr} );

####

my $r2 = relation( [
    { 'y' => 5, 'z' => 6 },
    { 'y' => 2, 'z' => 1 },
    { 'y' => 2, 'z' => 4 },
] );
pass( 'no death from instantiating $r2 with named-attrs format members' );
isa_ok( $r2, $sr_class_name );

my $got_r2_as_ofmt_perl = $r2->members( 1 );
pass( 'no death from extract $r2 members in named-attrs format' );
isa_ok( $got_r2_as_ofmt_perl, 'ARRAY' );
$got_r2_as_ofmt_perl->[1] = [sort {
        $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1]
    } @{$got_r2_as_ofmt_perl->[1]}];
my $exp_r2_as_ofmt_perl = [ [ 'y', 'z' ], [
    [ 2, 1 ],
    [ 2, 4 ],
    [ 5, 6 ],
] ];
is_deeply( $got_r2_as_ofmt_perl, $exp_r2_as_ofmt_perl, q{$r2o val corr} );

####

my $r3 = $r1->join( $r2 );
pass( 'no death from joining $r1 and $r2 to yield $r3' );
isa_ok( $r3, $sr_class_name );

####

my $got_r3_as_nfmt_perl = $r3->members();
pass( 'no death from extract $r3 members in named-attrs format' );
isa_ok( $got_r3_as_nfmt_perl, 'ARRAY' );
$got_r3_as_nfmt_perl = [sort {
           $a->{'x'} <=> $b->{'x'}
        || $a->{'y'} <=> $b->{'y'}
        || $a->{'z'} <=> $b->{'z'}
    } @{$got_r3_as_nfmt_perl}];
my $exp_r3_as_nfmt_perl = [
    { 'x' => 3, 'y' => 2, 'z' => 1 },
    { 'x' => 3, 'y' => 2, 'z' => 4 },
];
is_deeply( $got_r3_as_nfmt_perl, $exp_r3_as_nfmt_perl, q{$r3n val corr} );

my $got_r3_as_ofmt_perl = $r3->members( 1 );
pass( 'no death from extract $r3 members in named-attrs format' );
isa_ok( $got_r3_as_ofmt_perl, 'ARRAY' );
$got_r3_as_ofmt_perl->[1] = [sort {
        $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2]
    } @{$got_r3_as_ofmt_perl->[1]}];
my $exp_r3_as_ofmt_perl = [ [ 'x', 'y', 'z' ], [
    [ 3, 2, 1 ],
    [ 3, 2, 4 ],
] ];
is_deeply( $got_r3_as_ofmt_perl, $exp_r3_as_ofmt_perl, q{$r3o val corr} );

####

} # sub main

###########################################################################

1;
