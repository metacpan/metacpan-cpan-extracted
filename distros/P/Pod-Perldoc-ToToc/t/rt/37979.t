use Test::More 'no_plan';

BEGIN {
use lib qw( t/lib );
}

require "parse.pl";

my $output = parse_it( '37979.pod' );

my $expected = <<"HERE";
Chapter title
Section 1
	\$c->action
	\$c->action2()
	\$c - > action3
HERE

is( $output, $expected, "TOC comes out right" );
