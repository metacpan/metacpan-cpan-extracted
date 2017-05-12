#!/usr/bin/perl -w

BEGIN {
	use lib qw( t );
}

use strict;
use Test::More tests => 80;
# use Test::More qw(no_plan);

use my_dbi_conf;
use test_config;
test_config->recreate_tables;
require 'fill_tables.pl';

my ($h, $s);

my $t = 'fetch obj w/single inheritance';
ok( $h = Helicopter->fetch(8), $t );
is( ref($h), 'Helicopter', $t . ', ref of return val' );
is( $h->{class}, 'Helicopter', $t . ", 'class' field of return val" );
$t .= ', attr vals';
is( $h->{name}, 'Whirly Bird', $t );
cmp_ok( $h->{owner}, '==', 25, $t );
cmp_ok( $h->{ceiling}, '==', 7500, $t );
cmp_ok( $h->{lift_capacity}, '==', 800, $t );

$t = 'fetch obj w/multiple inheritance';
ok( $s = Seaplane->fetch(12), $t );
is( ref($s), 'Seaplane', $t . ', ref of return val' );
is( $s->{class}, 'Seaplane', $t . ", 'class' field of return val" );
$t .= ', attr vals';
is( $s->{name}, 'PuddleJumper', $t );
cmp_ok( $s->{owner}, '==', 20, $t );
cmp_ok( $s->{ceiling}, '==', 9000, $t );
cmp_ok( $s->{wingspan}, '==', 36, $t );
cmp_ok( $s->{min_depth}, '==', 2.5, $t );
cmp_ok( $s->{anchor}->id, '==', 17, $t );
cmp_ok( $s->{max_wave_height}, '==', 2, $t );

$t = 'fetch_group';
## get all vehicles owned by Bob
my $Bobs = Vehicle->fetch_group({where => 'owner = ?', value  => [ 20 ]});
$Bobs = [	map { $_->[1] }
			sort { $a->[0] <=> $b->[0] }
			map { [$_->id, $_ ] } @$Bobs ];
is( @$Bobs, 3, $t );
is( $Bobs->[0]->id, 5, $t );
is( ref $Bobs->[0], 'Boat', $t );
is( $Bobs->[1]->id, 7, $t );
is( ref $Bobs->[1], 'Aircraft', $t );
is( $Bobs->[2]->id, 12, $t );
is( ref $Bobs->[2], 'Seaplane', $t );

$t = 'pm_fetch';
my $v = Vehicle->pm_fetch( 5 );
isa_ok( $v, 'Boat', $t );

$t = 'fetch_group_by_field';
my $v_list = Vehicle->fetch_group_by_field( 'id', [ 5, 7, 12 ] );
$v_list = [	map { $_->[1] }
			sort { $a->[0] <=> $b->[0] }
			map { [$_->id, $_ ] } @$v_list ];
is_deeply( $v_list, $Bobs, $t );

$v_list = Vehicle->fetch_group_by_field( 'id', [ 5 .. 12 ], { where => 'owner = ?', value => [ 20 ] } );
$v_list = [	map { $_->[1] }
			sort { $a->[0] <=> $b->[0] }
			map { [$_->id, $_ ] } @$v_list ];
is_deeply( $v_list, $Bobs, $t . ', extra WHERE clause' );

$t = 'fetch_group_by_ids';
$v_list = Vehicle->fetch_group_by_ids( [ 5, 7, 12 ] );
is_deeply( $v_list, $Bobs, $t );

$v_list = Vehicle->fetch_group_by_ids( [ 7, 12, 5 ] );
unshift @$v_list, pop @$v_list;
is_deeply( $v_list, $Bobs, $t . ', different order' );

$v_list = Vehicle->fetch_group_by_ids( [ 5 .. 12 ], { where => 'owner = ?', value => [ 20 ] } );
is_deeply( $v_list, $Bobs, $t . ', extra WHERE clause' );

$t = 'refetch( $field )';
$v = Vehicle->fetch(1);
my $v2 = Vehicle->fetch(1);
my $f = 'owner';
my $vals = 23;
$v2->{$f} = $vals;
$v2->save;
my $rv = $v->refetch( $f );
cmp_ok( $rv, '==', $vals, $t );
cmp_ok( $v->{$f}, '==', $vals, $t );

$t = 'refetch( \@fields )';
$f = [ qw/ owner name / ];
$vals = [ 20, 'Herbie' ];
map { $v2->{$f->[$_]} = $vals->[$_] } 0..$#{$f};
$v2->save;
my @rv = $v->refetch( $f );
is_deeply( \@rv, $vals, $t );
cmp_ok($v->{$f->[0]}, 'eq', $vals->[0], $t );
cmp_ok($v->{$f->[1]}, '==', $vals->[1], $t );

$t = 'field_update( $field )';
$v = Vehicle->fetch(1);
$v->{owner} = 1;
ok( $v->field_update( 'owner' ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 1, $t );
cmp_ok( $v2->owner, '==', 1, $t );

$v->{owner} = 2;
$v->{name} = 'Bug';
ok( $v->field_update( 'name' ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 2, $t );
cmp_ok( $v2->owner, '==', 1, $t );
cmp_ok( $v->name, 'eq', 'Bug', $t );
cmp_ok( $v2->name, 'eq', 'Bug', $t );

$t = 'field_update( \@fields )';
$v->{name} = 'Pinto';
ok( $v->field_update( [ qw/ name owner / ] ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 2, $t );
cmp_ok( $v2->owner, '==', 2, $t );
cmp_ok( $v->name, 'eq', 'Pinto', $t );
cmp_ok( $v2->name, 'eq', 'Pinto', $t );

$t = 'field_update( \%fields )';
ok( $v->field_update( { owner => 4 } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 4, $t );
cmp_ok( $v2->owner, '==', 4, $t );

ok( $v->field_update( { owner => 3, name => 'Gremlin' } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 3, $t );
cmp_ok( $v2->owner, '==', 3, $t );
cmp_ok( $v->name, 'eq', 'Gremlin', $t );
cmp_ok( $v2->name, 'eq', 'Gremlin', $t );

$t = 'field_update( \%fields, { if_match => 1 } )';
ok( $v->field_update( { owner => 5 }, { if_match => 1 } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 5, $t );
cmp_ok( $v2->owner, '==', 5, $t );

$v->{owner} = 4;
ok( !$v->field_update( { owner => 6 }, { if_match => 1 } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 4, $t );
cmp_ok( $v2->owner, '==', 5, $t );

$t = 'field_update( \%fields, { if_match => \%match_vals } )';
ok( $v->field_update( { owner => 6 }, { if_match => { owner => 5 } } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 6, $t );
cmp_ok( $v2->owner, '==', 6, $t );

ok( !$v->field_update( { owner => 7 }, { if_match => { owner => 3, name => 'Gremlin' } } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 6, $t );
cmp_ok( $v2->owner, '==', 6, $t );
ok( !$v->field_update( { owner => 7 }, { if_match => { owner => 6, name => 'Gremlins' } } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 6, $t );
cmp_ok( $v2->owner, '==', 6, $t );
ok( $v->field_update( { owner => 7 }, { if_match => { owner => 6, name => 'Gremlin' } } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 7, $t );
cmp_ok( $v2->owner, '==', 7, $t );

$t = 'field_update( \%fields, { where => $where } )';
ok( !$v->field_update( { owner => 8 }, { where => 'owner < 7' } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 7, $t );
cmp_ok( $v2->owner, '==', 7, $t );

ok( $v->field_update( { owner => 8 }, { where => 'owner < 10' } ), $t );
$v2 = Vehicle->fetch(1);
cmp_ok( $v->owner, '==', 8, $t );
cmp_ok( $v2->owner, '==', 8, $t );

1;
