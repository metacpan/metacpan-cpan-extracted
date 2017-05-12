#!perl -T

use 5.006;
use strict;

use Data::Dumper;


use warnings FATAL => 'all';
use Test::More;

plan tests => 21;


use lib 'lib';

use Parse::Gnaw;
use Parse::Gnaw::LinkedList;
use Parse::Gnaw::LinkedListConstants;
use Parse::Gnaw::Blocks::LetterConstants;





my $teststring = "adeeeghhhifbghhhic";

my $ab_string=Parse::Gnaw::LinkedList->new($teststring);
$ab_string->display();

ok($ab_string->[LIST__FIRST_START]->[LETTER__DATA_PAYLOAD]    eq 'FIRSTSTART', "first is first"  );
ok($ab_string->[LIST__LAST_START]->[LETTER__DATA_PAYLOAD]     eq 'LASTSTART' , "last is last"    );
ok($ab_string->[LIST__CURR_START]->[LETTER__DATA_PAYLOAD]     eq 'FIRSTSTART', "current is first");


my $letter=$ab_string->[LIST__CURR_START]->[LETTER__NEXT_START];

my @characters = split(//, $teststring);
foreach my $character (@characters){

	ok($letter->[LETTER__DATA_PAYLOAD] eq $character, "next letter is '$character'");
	$letter=$letter->[LETTER__NEXT_START];
}


__DATA__

This test is doing basic checks for creating a one-dimensional string.



Dumping LinkedList object
LETPKG => Parse::Gnaw::Blocks::Letter # package name of letter objects
CONNMIN1 => 0 # max number of connections, minus 1
HEADING_DIRECTION_INDEX => 0
HEADING_PREVNEXT_INDEX  => 0
FIRSTSTART => 

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8a79768)
	payload: 'FIRSTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]

LASTSTART => 

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8a79588)
	payload: 'LASTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]

CURRPTR => 

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8a79768)
	payload: 'FIRSTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]


letters, by order of next_start_position()

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c659d4)
	payload: 'a'
	from: file t/llist_create_1d_nextstart.t, line 28, column 0
	connections:
		 [ ........... , (0x8c65bf0) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c65bf0)
	payload: 'd'
	from: file t/llist_create_1d_nextstart.t, line 28, column 1
	connections:
		 [ (0x8c659d4) , (0x8c65d08) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c65d08)
	payload: 'e'
	from: file t/llist_create_1d_nextstart.t, line 28, column 2
	connections:
		 [ (0x8c65bf0) , (0x8c65e20) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c65e20)
	payload: 'e'
	from: file t/llist_create_1d_nextstart.t, line 28, column 3
	connections:
		 [ (0x8c65d08) , (0x8c65f38) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c65f38)
	payload: 'e'
	from: file t/llist_create_1d_nextstart.t, line 28, column 4
	connections:
		 [ (0x8c65e20) , (0x8c66050) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c66050)
	payload: 'g'
	from: file t/llist_create_1d_nextstart.t, line 28, column 5
	connections:
		 [ (0x8c65f38) , (0x8c66168) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c66168)
	payload: 'h'
	from: file t/llist_create_1d_nextstart.t, line 28, column 6
	connections:
		 [ (0x8c66050) , (0x8c66280) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c66280)
	payload: 'h'
	from: file t/llist_create_1d_nextstart.t, line 28, column 7
	connections:
		 [ (0x8c66168) , (0x8c1ac9c) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1ac9c)
	payload: 'h'
	from: file t/llist_create_1d_nextstart.t, line 28, column 8
	connections:
		 [ (0x8c66280) , (0x8c1adb4) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1adb4)
	payload: 'i'
	from: file t/llist_create_1d_nextstart.t, line 28, column 9
	connections:
		 [ (0x8c1ac9c) , (0x8c1aecc) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1aecc)
	payload: 'f'
	from: file t/llist_create_1d_nextstart.t, line 28, column 10
	connections:
		 [ (0x8c1adb4) , (0x8c1afe4) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1afe4)
	payload: 'b'
	from: file t/llist_create_1d_nextstart.t, line 28, column 11
	connections:
		 [ (0x8c1aecc) , (0x8c1b0fc) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1b0fc)
	payload: 'g'
	from: file t/llist_create_1d_nextstart.t, line 28, column 12
	connections:
		 [ (0x8c1afe4) , (0x8c1b214) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1b214)
	payload: 'h'
	from: file t/llist_create_1d_nextstart.t, line 28, column 13
	connections:
		 [ (0x8c1b0fc) , (0x8c1b32c) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1b32c)
	payload: 'h'
	from: file t/llist_create_1d_nextstart.t, line 28, column 14
	connections:
		 [ (0x8c1b214) , (0x8c1b444) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1b444)
	payload: 'h'
	from: file t/llist_create_1d_nextstart.t, line 28, column 15
	connections:
		 [ (0x8c1b32c) , (0x8c1b55c) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1b55c)
	payload: 'i'
	from: file t/llist_create_1d_nextstart.t, line 28, column 16
	connections:
		 [ (0x8c1b444) , (0x8c1b674) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8c1b674)
	payload: 'c'
	from: file t/llist_create_1d_nextstart.t, line 28, column 17
	connections:
		 [ (0x8c1b55c) , ........... ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8a79588)
	payload: 'LASTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]





