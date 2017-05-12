#!/usr/bin/perl -w

BEGIN {
	use lib qw( t );
}

use strict;
use Test::More tests => 34;

use my_dbi_conf;
use test_config;

my ($h, $s);

##-----  empty new with single inheritance  -----
my $t = 'empty new() w/single inheritance';
ok( $h = Helicopter->new(), $t );
is( ref($h), 'Helicopter', $t . ', ref of return val' );
is( $h->{class}, 'Helicopter', $t . ", 'class' field of return val" );

$t = 'assign/check values of attributes';
$h->{name}				= 'Whirly Bird';
$h->{owner}				= 25;
$h->{ceiling}			= 7500;
$h->{lift_capacity}		= 800;
is( $h->{name}, 'Whirly Bird', $t );
cmp_ok( $h->{owner}, '==', 25, $t );
cmp_ok( $h->{ceiling}, '==', 7500, $t );
cmp_ok( $h->{lift_capacity}, '==', 800, $t );

##-----  empty new with multiple inheritance  -----
$t = 'empty new() w/multiple inheritance';
ok( $s = Seaplane->new(), $t );
is( ref($s), 'Seaplane', $t . ', ref of return val' );
is( $s->{class}, 'Seaplane', $t . ", 'class' field of return val" );

$t = 'assign/check values of attributes';
$s->{name}				= 'PuddleJumper';
$s->{owner}				= 20;
$s->{ceiling}			= 9000;
$s->{wingspan}			= 36;
$s->{min_depth}			= 2.5;
$s->{anchor}			= 17;
$s->{max_wave_height}	= 2;
is( $s->{name}, 'PuddleJumper', $t );
cmp_ok( $s->{owner}, '==', 20, $t );
cmp_ok( $s->{ceiling}, '==', 9000, $t );
cmp_ok( $s->{wingspan}, '==', 36, $t );
cmp_ok( $s->{min_depth}, '==', 2.5, $t );
cmp_ok( $s->{anchor}, '==', 17, $t );
cmp_ok( $s->{max_wave_height}, '==', 2, $t );

##-----  initialized new with single inheritance  -----
$t = 'new( { init vals } ) w/single inheritance';
ok( $h = Helicopter->new( {	name			=> 'Whirly Bird',
						owner			=> 25,
						ceiling			=> 7500,
						lift_capacity	=> 800
					} ), $t );
is( ref($h), 'Helicopter', $t . ', ref of return val' );
is( $h->{class}, 'Helicopter', $t . ", 'class' field of return val" );

$t .= ', attr vals';
is( $h->{name}, 'Whirly Bird', $t );
cmp_ok( $h->{owner}, '==', 25, $t );
cmp_ok( $h->{ceiling}, '==', 7500, $t );
cmp_ok( $h->{lift_capacity}, '==', 800, $t );

##-----  initialized new with multiple inheritance  -----
$t = 'new( { init vals } ) w/multiple inheritance';
ok( $s = Seaplane->new( {	name			=> 'PuddleJumper',
						owner			=> 20,
						ceiling			=> 9000,
						wingspan		=> 36,
						min_depth		=> 2.5,
						anchor			=> 17,
						max_wave_height	=> 2
					} ), $t );
is( ref($s), 'Seaplane', $t . ', ref of return val' );
is( $s->{class}, 'Seaplane', $t . ", 'class' field of return val" );

$t .= ', attr vals';
is( $s->{name}, 'PuddleJumper', $t );
cmp_ok( $s->{owner}, '==', 20, $t );
cmp_ok( $s->{ceiling}, '==', 9000, $t );
cmp_ok( $s->{wingspan}, '==', 36, $t );
cmp_ok( $s->{min_depth}, '==', 2.5, $t );
cmp_ok( $s->{anchor}, '==', 17, $t );
cmp_ok( $s->{max_wave_height}, '==', 2, $t );

1;
