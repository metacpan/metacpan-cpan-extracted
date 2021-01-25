#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings;
use Neo4j::Types::Point;

plan tests => 8+2+2 + 8+2+2+2 + 6+6+6+6+1 + 1;



my (@c, $p);

sub new_point { bless shift, 'Neo4j::Types::Point' }



@c = ( 2.294, 48.858, 396 );
$p = new_point [ 4979, @c ];
is $p->srid(), 4979, 'eiffel srid';
is $p->X(), 2.294, 'eiffel X';
is $p->Y(), 48.858, 'eiffel Y';
is $p->Z(), 396, 'eiffel Z';
is $p->longitude(), 2.294, 'eiffel lon';
is $p->latitude(), 48.858, 'eiffel lat';
is $p->height(), 396, 'eiffel ellipsoidal height';
is_deeply [$p->coordinates], [@c], 'eiffel coords';

@c = ( 2.294, 48.858, 396 );
$p = new_point [ 4326, @c ];
is $p->srid(), 4326, 'eiffel 2d srid';
is_deeply [$p->coordinates], [@c], 'eiffel 3d coords';

@c = ( 2.294, 48.858 );
$p = new_point [ 4979, @c ];
is $p->srid(), 4979, 'eiffel 3d srid';
is_deeply [$p->coordinates], [@c], 'eiffel 2d coords';



@c = ( 12, 34 );
$p = new_point [ 7203, @c ];
is $p->srid(), 7203, 'plane srid';
is $p->X(), 12, 'plane X';
is $p->Y(), 34, 'plane Y';
ok ! defined $p->Z(), 'plane Z';
is $p->longitude(), 12, 'plane lon';
is $p->latitude(), 34, 'plane lat';
ok ! defined $p->height(), 'plane height';
is_deeply [$p->coordinates], [@c], 'plane coords';

@c = ( 56, 78, 90 );
$p = new_point [ 9157, @c ];
is $p->srid(), 9157, 'space srid';
is_deeply [$p->coordinates], [@c], 'space coords';

@c = ( 361, -91 );
$p = new_point [ 4326, @c ];
is $p->srid(), 4326, 'ootw srid';
is_deeply [$p->coordinates], [@c], 'ootw coords';

@c = ( 'what', 'ever' );
$p = new_point [ 'onetwothree', @c ];
is $p->srid(), 'onetwothree', 'string srid';
is_deeply [$p->coordinates], [@c], 'string coords';



@c = ( 42 );
throws_ok { Neo4j::Types::Point->new( 4326, @c ) } qr/\bdimensions\b/i, 'new 4326 X fails';
throws_ok { Neo4j::Types::Point->new( 4979, @c ) } qr/\bdimensions\b/i, 'new 4979 X fails';
throws_ok { Neo4j::Types::Point->new( 7203, @c ) } qr/\bdimensions\b/i, 'new 7203 X fails';
throws_ok { Neo4j::Types::Point->new( 9157, @c ) } qr/\bdimensions\b/i, 'new 9157 X fails';
throws_ok { Neo4j::Types::Point->new( 12345, @c ) } qr/\bUnsupported\b/i, 'new 12345 X fails';
throws_ok { Neo4j::Types::Point->new( undef, @c ) } qr/\bSRID\b/i, 'new undef X fails';

@c = ( 2.294, 48.858 );
$p = Neo4j::Types::Point->new( 4326, @c );
is_deeply $p, new_point([ 4326, @c[0..1] ]), 'new 4326';
throws_ok { Neo4j::Types::Point->new( 4979, @c ) } qr/\bdimensions\b/i, 'new 4979 XY fails';
$p = Neo4j::Types::Point->new( 7203, @c );
is_deeply $p, new_point([ 7203, @c[0..1] ]), 'new 7203';
throws_ok { Neo4j::Types::Point->new( 9157, @c ) } qr/\bdimensions\b/i, 'new 9157 XY fails';
throws_ok { Neo4j::Types::Point->new( 12345, @c ) } qr/\bUnsupported\b/i, 'new 12345 XY fails';
throws_ok { Neo4j::Types::Point->new( undef, @c ) } qr/\bSRID\b/i, 'new undef XY fails';

@c = ( 2.294, 48.858, 396 );
$p = Neo4j::Types::Point->new( 4326, @c );
is_deeply $p, new_point([ 4326, @c[0..1] ]), 'new 4326 Z ignored';
$p = Neo4j::Types::Point->new( 4979, @c );
is_deeply $p, new_point([ 4979, @c ]), 'new 4979';
$p = Neo4j::Types::Point->new( 7203, @c );
is_deeply $p, new_point([ 7203, @c[0..1] ]), 'new 7203 Z ignored';
$p = Neo4j::Types::Point->new( 9157, @c );
is_deeply $p, new_point([ 9157, @c ]), 'new 9157';
throws_ok { Neo4j::Types::Point->new( 12345, @c ) } qr/\bUnsupported\b/i, 'new 12345 XYZ fails';
throws_ok { Neo4j::Types::Point->new( undef, @c ) } qr/\bSRID\b/i, 'new undef XYZ fails';

@c = ( 2.294, 48.858, 396, 13 );
$p = Neo4j::Types::Point->new( 4326, @c );
is_deeply $p, new_point([ 4326, @c[0..1] ]), 'new 4326 ZM ignored';
$p = Neo4j::Types::Point->new( 4979, @c );
is_deeply $p, new_point([ 4979, @c[0..2] ]), 'new 4979 M ignored';
$p = Neo4j::Types::Point->new( 7203, @c );
is_deeply $p, new_point([ 7203, @c[0..1] ]), 'new 7203 ZM ignored';
$p = Neo4j::Types::Point->new( 9157, @c );
is_deeply $p, new_point([ 9157, @c[0..2] ]), 'new 9157 M ignored';
throws_ok { Neo4j::Types::Point->new( 12345, @c ) } qr/\bUnsupported\b/i, 'new 12345 XYZM fails';
throws_ok { Neo4j::Types::Point->new( undef, @c ) } qr/\bSRID\b/i, 'new undef XYZM fails';

@c = ( undef, 45 );
$p = Neo4j::Types::Point->new( 4326, @c );
is_deeply $p, new_point([ 4326, @c[0..1] ]), 'new 4326 undef coord';



done_testing;
