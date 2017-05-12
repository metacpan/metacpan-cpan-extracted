#!/usr/bin/perl -w

BEGIN {
	use lib qw( t );
}

use strict;
use Test::More tests => 20;

use my_dbi_conf;
use test_config;
test_config->recreate_tables;
require 'fill_tables.pl';

my ($v, $p, $s, $a, $by, $slips);

##-----  fetch method  -----
my $t = 'fetch method';
$v = Vehicle->fetch(1);
ok( $p = $v->owner_PersonAlias, $t );
is( ref($p), 'Person', $t . ', ref of return val' );
cmp_ok( $p->id, '==', 24, $t . ', id of return val' );

##-----  forward direction auto-fetching  -----
$t = 'forward direction auto-fetching';
$s = Seaplane->fetch(12);
$a = $s->{anchor};
is( ref($a), 'Anchor', $t . ', ref of return val' );
cmp_ok( $a->id, '==', 17, $t . ', id of return val' );

##-----  backward direction auto-fetching  -----
$t = 'backward direction auto-fetching';
$by = Boatyard->fetch(30);
$slips = $by->{list_of_slips};
is( @$slips, 3, $t );
cmp_ok( grep(ref($_) ne 'Slip', @$slips), '==', 0, $t );
is_deeply( [sort map { $_->id } @$slips], [34 .. 36], $t );

##-----  forward direction auto-save  -----
$t = 'forward direction auto-save (id in field)';
$a = Anchor->new({weight => 203});
$a->save;
$s = Seaplane->new( {	name			=> 'Albatross',
						owner			=> 17,
						ceiling			=> 19000,
						wingspan		=> 50,
						min_depth		=> 10,
						anchor			=> $a->id,
						max_wave_height	=> 4
					} );
$s->save;
$a = $s->{anchor};
is( ref($a), 'Anchor', $t . ', ref after save' );
cmp_ok( Anchor->fetch($a->id)->weight, '==', 203, $t . ', correct obj' );

## save with object in anchor field
$t = 'forward direction auto-save (unsaved obj in field)';
$s->remove;
$s = Seaplane->new( {	name			=> 'Albatross',
						owner			=> 17,
						ceiling			=> 19000,
						wingspan		=> 50,
						min_depth		=> 10,
						anchor			=> Anchor->new({weight => 250}),
						max_wave_height	=> 4
					} );
$s->save;
$a = $s->{anchor};
is( ref($a), 'Anchor', $t . ', ref after save' );
cmp_ok( Anchor->fetch($a->id)->weight, '==', 250, $t . ', correct obj' );

$t = 'save obj with auto-fetched obj and nosave flag';
$s->remove;
use BoatNoSaveAnchor;
$a = Anchor->new( { weight => 5000 } )->save;
$s = BoatNoSaveAnchor->new( {	name			=> 'Big Ship',
								owner			=> 17,
								min_depth		=> 10,
								anchor			=> $a
					} );
$s->save;
$a = $s->{anchor};
is( ref($a), 'Anchor', $t . ', ref after save' );
cmp_ok( Anchor->fetch($a->id)->weight, '==', 5000, $t . ', correct obj' );

##-----  backward direction auto-save  -----
$t = 'backward direction auto-save';
$by = Boatyard->new( { name => 'Dock City'} );
$by->{list_of_slips} = 	[	Slip->new( {number => 1} ),
							Slip->new( {number => 2} ),
							Slip->new( {number => 3} ),
							Slip->new( {number => 4} )
						];
$by->save;
$slips = $by->{list_of_slips};
is( @$slips, 4, $t );
is_deeply( [map $_->{boatyard}, @$slips], [map $by->id, @$slips], $t);

$by = Boatyard->fetch($by->id);
$slips = $by->{list_of_slips};
is( @$slips, 4, $t );
is_deeply( [map $_->number, @$slips], [1..4], $t);

##-----  forward direction auto-remove  -----
$t = 'forward direction auto-remove';
my ($args, $row);
$s->remove;
$args = {	from => [ Anchor->base_table ],
			select => [ 'count(*)'],
			where => Anchor->id_clause($a->id, undef, undef),
			return => 'single'
		};
$row = eval { Anchor->db_select($args);	};
is( $row->[0], 0, $t );

##-----  backward direction auto-remove  -----
$t = 'backward direction auto-remove';
$by->remove;
$args = {	from => [ Slip->base_table ],
			select => [ 'count(*)'],
			where => 'boatyard = ' . $by->id,
			return => 'single'
		};
$row = eval { Slip->db_select($args);	};
is( $row->[0], 0, $t );

1;
