#!/usr/bin/perl -w

BEGIN {
	use lib qw( t );
}

use strict;
use Test::More tests => 46;

use my_dbi_conf;
use test_config;
test_config->recreate_tables;
require 'fill_tables.pl';

my ($h, $s);

##-----  single inheritance clone --
my $t = 'clone obj w/single inheritance';
$h = Helicopter->fetch(8);
ok( $s = $h->clone, $t );
is( ref($s), 'Helicopter', $t . ', ref of return val' );
is( $s->{class}, 'Helicopter', $t . ", 'class' field of return val" );
ok( $s ne $h, $t . ', new address' );

## check attributes before saving
$t .= ', attr vals';
is( $s->{name}, 'Whirly Bird', $t );
cmp_ok( $s->{owner}, '==', 25, $t );
cmp_ok( $s->{ceiling}, '==', 7500, $t );
cmp_ok( $s->{lift_capacity}, '==', 800, $t );

## and after saving and re-fetching
$s->save;
$s = Helicopter->fetch($s->id);
$t .= ', after save & re-fetch';
is( $s->{name}, 'Whirly Bird', $t );
cmp_ok( $s->{owner}, '==', 25, $t );
cmp_ok( $s->{ceiling}, '==', 7500, $t );
cmp_ok( $s->{lift_capacity}, '==', 800, $t );
undef $h;

##-- multiple inheritance clone --
$t = 'clone obj w/multiple inheritance';
$s = Seaplane->fetch(12);
ok( $h = $s->clone, $t );
is( ref($h), 'Seaplane', $t . ', ref of return val' );
is( $h->{class}, 'Seaplane', $t . ", 'class' field of return val" );
ok( $s ne $h, $t . ', new address' );

$t .= ', attr vals';
is( $h->{name}, 'PuddleJumper', $t );
cmp_ok( $h->{owner}, '==', 20, $t );
cmp_ok( $h->{ceiling}, '==', 9000, $t );
cmp_ok( $h->{wingspan}, '==', 36, $t );
cmp_ok( $h->{min_depth}, '==', 2.5, $t );
cmp_ok( $h->{anchor}->id, '==', 17, $t );
cmp_ok( $h->{max_wave_height}, '==', 2, $t );

## and after saving and re-fetching
$t .= ' after save & re-fetch';
$h->save;
$h = Seaplane->fetch($h->id);
is( $h->{name}, 'PuddleJumper', $t );
cmp_ok( $h->{owner}, '==', 20, $t );
cmp_ok( $h->{ceiling}, '==', 9000, $t );
cmp_ok( $h->{wingspan}, '==', 36, $t );
cmp_ok( $h->{min_depth}, '==', 2.5, $t );
cmp_ok( $h->{anchor}->id, '==', 17, $t );
cmp_ok( $h->{max_wave_height}, '==', 2, $t );

## check cloning with false values;
$t = 'clone obj with values';
$s = Seaplane->fetch(12);
$h = $s->clone( { ceiling => 10000, min_depth => 0 } );
is( $h->{name}, 'PuddleJumper', $t );
cmp_ok( $h->{owner}, '==', 20, $t );
cmp_ok( $h->{ceiling}, '==', 10000, $t );
cmp_ok( $h->{wingspan}, '==', 36, $t );
cmp_ok( $h->{min_depth}, '==', 0, $t );
cmp_ok( $h->{anchor}->id, '==', 17, $t );
cmp_ok( $h->{max_wave_height}, '==', 2, $t );
$h = undef;

## check cloning with false values;
$t = 'clone obj with values (of object with missing fields)';
$s = Seaplane->new;
$h = $s->clone( { ceiling => 30000, min_depth => 6 } );
cmp_ok( $h->{ceiling}, '==', 30000, $t );
cmp_ok( $h->{min_depth}, '==', 6, $t );
$h = undef;

$t = 'clone (& save) obj with values';
$s = Seaplane->fetch(12);
$h = $s->clone( { ceiling => 10000, min_depth => 0 } )->save;
is( $h->{name}, 'PuddleJumper', $t );
cmp_ok( $h->{owner}, '==', 20, $t );
cmp_ok( $h->{ceiling}, '==', 10000, $t );
cmp_ok( $h->{wingspan}, '==', 36, $t );
cmp_ok( $h->{min_depth}, '==', 0, $t );
cmp_ok( $h->{anchor}->id, '==', 17, $t );
cmp_ok( $h->{max_wave_height}, '==', 2, $t );

1;
