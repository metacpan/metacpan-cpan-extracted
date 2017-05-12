#!perl

use Test::More tests => 13;

use strict;
use warnings;

BEGIN { use_ok( 'String::Interpolate::Shell', 'strinterp' ); }


my %vars = ( a => 1,
	     b => 'a',
	     d => 'Horse'
	     );


my @tests = (

	     [ '1',     '$a' ],
	     [ '1',     '${a}' ],
	     [ '1.0',   '${a::%.1f}' ],
	     [ 'a',     '$b' ],
	     [ '1',     '${!b}' ],
	     [ 'Horse', '$d' ],
	     [ 'Snow',  '${d:+Snow}' ],
	     [ 'a',     '${d:+$b}' ],
	     [ 'Horsy', '${d:~tr/e/y/}' ],
	     [ 'Hearsae', '${d:~s/ors/earsa/}' ],
	     [ 'Hqrsq', '${d:~s/[aeiou]/q/g}' ],
	     [ 'Horsy', '${e:-Horsy}' ],

);

for my $test ( @tests ) {

    my ( $exp, $tpl ) = @$test;

    is( strinterp( $tpl, \%vars ), $exp, $tpl );

}
