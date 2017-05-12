#!perl -w

use Test::More tests=>1;

my @expected = <DATA>;
my @actual = `blib/script/pod-outline t/indent.pod`;

is_deeply( \@actual, \@expected );

__DATA__
HEADING 1

    Should be indented 4

    HEADING 2 A (Should be indented 4)

	Should be indented 8

	* Bullet 1

	* Bullet 2

HEADING 1 again

    HEADING 2 B (Should be indented 4)

	Should be indented 8

	HEADING3 A (should be in 8)

	    Should be in 12

	HEADING3 B (should be in 8)

	    Should be in 12

	    HEADING4 A (should be in 12)

		Should be in 16

		  1 Mega-indent

		  2 Mega-indent

	HEADING3 C (should be in 8)

	    Should be in 12

HEADING 1 A

    Should be indented 4

