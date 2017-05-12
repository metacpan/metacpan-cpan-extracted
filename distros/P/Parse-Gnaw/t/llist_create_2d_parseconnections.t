#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;


use Test::More;

plan tests => 84;


use lib 'lib';

use Parse::Gnaw::LinkedListDimensions2;
use Parse::Gnaw::LinkedListConstants;
use Parse::Gnaw::Blocks::Letter;
use Parse::Gnaw::Blocks::LetterConstants;

# we're going to construct a basic 2-dimensional string linked list to parse
# but we're not going to run a grammar on it.
# we're just going to see that the 2D linked list got created correctly.

my $textblock=<<'TEXTBLOCK';
abc
def
ghi
TEXTBLOCK

my $string=Parse::Gnaw::LinkedListDimensions2->new(string=>$textblock);


print $string->display; 


ok($string->[LIST__FIRST_START]->[1]    eq 'FIRSTSTART', "first is first"  );
ok($string->[LIST__LAST_START]->[1]     eq 'LASTSTART' , "last is last"    );
ok($string->[LIST__CURR_START]->[1]     eq 'FIRSTSTART', "current is first");

sub connection_test{
	my($direction, $letter, $index,$next_prev, $expected)=@_;

	my $thispayload = $letter->[LETTER__DATA_PAYLOAD] || '.';
	my $actpayload  = $letter->[LETTER__CONNECTIONS]->[$index]->[$next_prev]->[LETTER__DATA_PAYLOAD] || '.';
	my $string = "'$thispayload' $index $next_prev ($direction) is '$expected'";

	ok($actpayload eq $expected, $string);

}

sub right    { connection_test( 'right    ', shift(@_), 0, LETTER__CONNECTION_NEXT, shift(@_) ); }
sub left     { connection_test( 'left     ', shift(@_), 0, LETTER__CONNECTION_PREV, shift(@_) ); }
sub downright{ connection_test( 'downright', shift(@_), 1, LETTER__CONNECTION_NEXT, shift(@_) ); }
sub upleft   { connection_test( 'upleft   ', shift(@_), 1, LETTER__CONNECTION_PREV, shift(@_) ); }
sub down     { connection_test( 'down     ', shift(@_), 2, LETTER__CONNECTION_NEXT, shift(@_) ); }
sub up       { connection_test( 'up       ', shift(@_), 2, LETTER__CONNECTION_PREV, shift(@_) ); }
sub downleft { connection_test( 'downleft ', shift(@_), 3, LETTER__CONNECTION_NEXT, shift(@_) ); }
sub upright  { connection_test( 'upright  ', shift(@_), 3, LETTER__CONNECTION_PREV, shift(@_) ); }

# this subroutine checks the connections between the letter in the center 
# and all the letters around it in a 3x3 grid.
# for example, given this text block:
#
# a b c
# d e f
# g h i
#
# set $letter to the letter containing 'e', then call this:
# three_by_three_grid($letter, "abcdefghi");
#
# if there is no connection in a particular spot in the grid, put a period '.' in the string
#
sub three_by_three_grid {
	my $letter=shift(@_);

	my $letters=shift(@_);
	my @l=split(//,$letters);

	upleft		($letter,shift(@l));
	up		($letter,shift(@l));
	upright		($letter,shift(@l));
	left		($letter,shift(@l));
	shift(@l);
	right		($letter,shift(@l));
	downleft	($letter,shift(@l));
	down		($letter,shift(@l));
	downright	($letter,shift(@l));
}

# abc
# def
# ghi

my $letter=$string->[LIST__CURR_START]->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'a', "first letter is 'a'");
three_by_three_grid($letter, "....ab.de");

$letter=$letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'b', "next letter is 'b'");
three_by_three_grid($letter, "...abcdef");

$letter=$letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'c', "next letter is 'c'");
three_by_three_grid($letter, "...bc.ef.");

$letter=$letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'd', "next letter is 'd'");
three_by_three_grid($letter, ".ab.de.gh");

$letter=$letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'e', "next letter is 'e'");
three_by_three_grid($letter, "abcdefghi");

$letter=$letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'f', "next letter is 'f'");
three_by_three_grid($letter, "bc.ef.hi.");

$letter=$letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'g', "next letter is 'g'");
three_by_three_grid($letter, ".de.gh...");

$letter=$letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'h', "next letter is 'h'");
three_by_three_grid($letter, "defghi...");

$letter=$letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'i', "next letter is 'i'");
three_by_three_grid($letter, "ef.hi....");


__DATA__


Dumping LinkedList object
LETPKG => Parse::Gnaw::Blocks::LetterDimensions2 # package name of letter objects
CONNMIN1 => 3 # max number of connections, minus 1
HEADING_DIRECTION_INDEX => 0
HEADING_PREVNEXT_INDEX  => 0
FIRSTSTART => 

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94da9a0)
	 payload: 'FIRSTSTART'
	 location: unknown
	connections:
		.................................
		...........(0x94da9a0)...........
		.................................
LASTSTART => 

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94daba8)
	 payload: 'LASTSTART'
	 location: unknown
	connections:
		.................................
		...........(0x94daba8)...........
		.................................
CURRPTR => 

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94da9a0)
	 payload: 'FIRSTSTART'
	 location: unknown
	connections:
		.................................
		...........(0x94da9a0)...........
		.................................

letters, by order of next_start_position()

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94e26f8)
	 payload: 'a'
	 location: file t/llist_create_2d_parseconnections.t, line 32, textline 1, column 0
	connections:
		.................................
		...........(0x94e26f8)(0x94e2928)
		...........(0x94e2f90)(0x94e2d88)

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94e2928)
	 payload: 'b'
	 location: file t/llist_create_2d_parseconnections.t, line 32, textline 1, column 1
	connections:
		.................................
		(0x94e26f8)(0x94e2928)(0x94e2b30)
		(0x94e2d88)(0x94e3198)(0x94e2f90)

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94e2b30)
	 payload: 'c'
	 location: file t/llist_create_2d_parseconnections.t, line 32, textline 1, column 2
	connections:
		.................................
		(0x94e2928)(0x94e2b30)...........
		(0x94e2f90)...........(0x94e3198)

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94e2d88)
	 payload: 'd'
	 location: file t/llist_create_2d_parseconnections.t, line 32, textline 2, column 0
	connections:
		(0x94e26f8)...........(0x94e2928)
		...........(0x94e2d88)(0x94e2f90)
		...........(0x94e35ec)(0x94e33c8)

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94e2f90)
	 payload: 'e'
	 location: file t/llist_create_2d_parseconnections.t, line 32, textline 2, column 1
	connections:
		(0x94e2928)(0x94e26f8)(0x94e2b30)
		(0x94e2d88)(0x94e2f90)(0x94e3198)
		(0x94e33c8)(0x94e37f4)(0x94e35ec)

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94e3198)
	 payload: 'f'
	 location: file t/llist_create_2d_parseconnections.t, line 32, textline 2, column 2
	connections:
		(0x94e2b30)(0x94e2928)...........
		(0x94e2f90)(0x94e3198)...........
		(0x94e35ec)...........(0x94e37f4)

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94e33c8)
	 payload: 'g'
	 location: file t/llist_create_2d_parseconnections.t, line 32, textline 3, column 0
	connections:
		(0x94e2d88)...........(0x94e2f90)
		...........(0x94e33c8)(0x94e35ec)
		.................................

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94e35ec)
	 payload: 'h'
	 location: file t/llist_create_2d_parseconnections.t, line 32, textline 3, column 1
	connections:
		(0x94e2f90)(0x94e2d88)(0x94e3198)
		(0x94e33c8)(0x94e35ec)(0x94e37f4)
		.................................

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94e37f4)
	 payload: 'i'
	 location: file t/llist_create_2d_parseconnections.t, line 32, textline 3, column 2
	connections:
		(0x94e3198)(0x94e2f90)...........
		(0x94e35ec)(0x94e37f4)...........
		.................................

	 letterobject: Parse::Gnaw::Blocks::LetterDimensions2=ARRAY(0x94daba8)
	 payload: 'LASTSTART'
	 location: unknown
	connections:
		.................................
		...........(0x94daba8)...........
		.................................
ok 1 - first is first
ok 2 - last is last
ok 3 - current is first
ok 4 - first letter is 'a'
ok 5 - 'a' 1 1 (upleft   ) is '.'
ok 6 - 'a' 2 1 (up       ) is '.'
ok 7 - 'a' 3 1 (upright  ) is '.'
ok 8 - 'a' 0 1 (left     ) is '.'
ok 9 - 'a' 0 0 (right    ) is 'b'
ok 10 - 'a' 3 0 (downleft ) is '.'
ok 11 - 'a' 2 0 (down     ) is 'd'
ok 12 - 'a' 1 0 (downright) is 'e'
ok 13 - next letter is 'b'
ok 14 - 'b' 1 1 (upleft   ) is '.'
ok 15 - 'b' 2 1 (up       ) is '.'
ok 16 - 'b' 3 1 (upright  ) is '.'
ok 17 - 'b' 0 1 (left     ) is 'a'
ok 18 - 'b' 0 0 (right    ) is 'c'
ok 19 - 'b' 3 0 (downleft ) is 'd'
ok 20 - 'b' 2 0 (down     ) is 'e'
ok 21 - 'b' 1 0 (downright) is 'f'
ok 22 - next letter is 'c'
ok 23 - 'c' 1 1 (upleft   ) is '.'
ok 24 - 'c' 2 1 (up       ) is '.'
ok 25 - 'c' 3 1 (upright  ) is '.'
ok 26 - 'c' 0 1 (left     ) is 'b'
ok 27 - 'c' 0 0 (right    ) is '.'
ok 28 - 'c' 3 0 (downleft ) is 'e'
ok 29 - 'c' 2 0 (down     ) is 'f'
ok 30 - 'c' 1 0 (downright) is '.'
ok 31 - next letter is 'd'
ok 32 - 'd' 1 1 (upleft   ) is '.'
ok 33 - 'd' 2 1 (up       ) is 'a'
ok 34 - 'd' 3 1 (upright  ) is 'b'
ok 35 - 'd' 0 1 (left     ) is '.'
ok 36 - 'd' 0 0 (right    ) is 'e'
ok 37 - 'd' 3 0 (downleft ) is '.'
ok 38 - 'd' 2 0 (down     ) is 'g'
ok 39 - 'd' 1 0 (downright) is 'h'
ok 40 - next letter is 'e'
ok 41 - 'e' 1 1 (upleft   ) is 'a'
ok 42 - 'e' 2 1 (up       ) is 'b'
ok 43 - 'e' 3 1 (upright  ) is 'c'
ok 44 - 'e' 0 1 (left     ) is 'd'
ok 45 - 'e' 0 0 (right    ) is 'f'
ok 46 - 'e' 3 0 (downleft ) is 'g'
ok 47 - 'e' 2 0 (down     ) is 'h'
ok 48 - 'e' 1 0 (downright) is 'i'
ok 49 - next letter is 'f'
ok 50 - 'f' 1 1 (upleft   ) is 'b'
ok 51 - 'f' 2 1 (up       ) is 'c'
ok 52 - 'f' 3 1 (upright  ) is '.'
ok 53 - 'f' 0 1 (left     ) is 'e'
ok 54 - 'f' 0 0 (right    ) is '.'
ok 55 - 'f' 3 0 (downleft ) is 'h'
ok 56 - 'f' 2 0 (down     ) is 'i'
ok 57 - 'f' 1 0 (downright) is '.'
ok 58 - next letter is 'g'
ok 59 - 'g' 1 1 (upleft   ) is '.'
ok 60 - 'g' 2 1 (up       ) is 'd'
ok 61 - 'g' 3 1 (upright  ) is 'e'
ok 62 - 'g' 0 1 (left     ) is '.'
ok 63 - 'g' 0 0 (right    ) is 'h'
ok 64 - 'g' 3 0 (downleft ) is '.'
ok 65 - 'g' 2 0 (down     ) is '.'
ok 66 - 'g' 1 0 (downright) is '.'
ok 67 - next letter is 'h'
ok 68 - 'h' 1 1 (upleft   ) is 'd'
ok 69 - 'h' 2 1 (up       ) is 'e'
ok 70 - 'h' 3 1 (upright  ) is 'f'
ok 71 - 'h' 0 1 (left     ) is 'g'
ok 72 - 'h' 0 0 (right    ) is 'i'
ok 73 - 'h' 3 0 (downleft ) is '.'
ok 74 - 'h' 2 0 (down     ) is '.'
ok 75 - 'h' 1 0 (downright) is '.'
ok 76 - next letter is 'i'
ok 77 - 'i' 1 1 (upleft   ) is 'e'
ok 78 - 'i' 2 1 (up       ) is 'f'
ok 79 - 'i' 3 1 (upright  ) is '.'
ok 80 - 'i' 0 1 (left     ) is 'h'
ok 81 - 'i' 0 0 (right    ) is '.'
ok 82 - 'i' 3 0 (downleft ) is '.'
ok 83 - 'i' 2 0 (down     ) is '.'
ok 84 - 'i' 1 0 (downright) is '.'


