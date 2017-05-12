#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
}

use lib '../lib';

use strict;
use Test::More tests => 15;
use Scalar::Util 'blessed';

my $module = 'SUPER';
use_ok($module) or die;

my $obj = Level4->new;
isa_ok( $obj, 'Level4' );

is( $obj->good_stuff, 'this has done good stuff',
	'...the object is initialized as level4'
);

my @parents = SUPER::get_all_parents( $obj, blessed($obj) );
is_deeply( \@parents, [qw( Level3 Level2 Level1 UNIVERSAL )],
	'...the object has four parents from its own class.'
);

@parents = SUPER::get_all_parents( $obj, 'Level3' );
is_deeply( \@parents, [qw( Level2 Level1 UNIVERSAL )],
	'... 3 parents from one class above.'
);

@parents = SUPER::get_all_parents( $obj, 'Level2' );
is_deeply( \@parents, [qw( Level1 UNIVERSAL )],
	'...2 parents from two classes above.' );

@parents = SUPER::get_all_parents( $obj, 'Level1' );
is_deeply( \@parents, [ 'UNIVERSAL' ],
	'...and only UNIVERSAL from the top level class.' );

my ( $sub, $parent ) =
	SUPER::find_parent( blessed($obj), 'good_stuff', 'Level4', $obj );
is( $sub, \&Level3::good_stuff, '...get the expected superclass method.' );
is( $parent, 'Level3', '...in the expected superclass.' );

( $sub, $parent ) =
	SUPER::find_parent( blessed($obj), 'good_stuff', 'Level3', $obj );
is( $sub, \&Level2::good_stuff,
	'...get the expected superclass method one up.' );
is( $parent, 'Level2', '...in the superclass one up.' );

( $sub, $parent ) =
	SUPER::find_parent( blessed($obj), 'good_stuff', 'Level2', $obj );
is( $sub, \&Level1::good_stuff,
	'...get the expected superclass method two up.' );
is( $parent, 'Level1', '...in the superclass two up.' );

( $sub, $parent ) =
	SUPER::find_parent( blessed($obj), 'good_stuff', 'Level1', $obj );
is( $sub, '', '...get an empty string when there are no more super class.' );
is( $parent, undef,
	'...and undef when no further superclasses match the desired method.' );

exit;

package Level1;

sub new { bless {}, $_[0] }

sub good_stuff { return "this has done good stuff" }

package Level2;

use base 'Level1';

sub good_stuff { $_[0]->SUPER; }

package Level3;

use base 'Level2';

sub good_stuff { $_[0]->SUPER; }

package Level4;

use base 'Level3';
