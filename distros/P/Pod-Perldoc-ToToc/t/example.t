# $Id$

use Test::More 'no_plan';

BEGIN {
use lib qw( t/lib );
}

require "parse.pl";

my $output = parse_it( 'example.pod' );

my $expected = <<"HERE";
Chapter title
Section 1
	Section 1 Subsection 1
	Section 1 Subsection 2
	Section 1 Subsection 3
		Section 1 Subsection 3 Subsubsection 1
		Section 1 Subsection 3 Subsubsection 2
Section 2
Section 3
HERE

is( $output, $expected, "TOC comes out right" );