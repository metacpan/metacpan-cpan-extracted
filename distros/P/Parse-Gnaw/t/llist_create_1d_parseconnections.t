#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;


use Test::More;

plan tests => 13;


use lib 'lib';

use Parse::Gnaw;
use Parse::Gnaw::LinkedList;
use Parse::Gnaw::LinkedListConstants;
use Parse::Gnaw::Blocks::LetterConstants;

my $ab_string;


$ab_string=Parse::Gnaw::LinkedList->new('abcd');
$ab_string->display();

my $letter=$ab_string->[LIST__CURR_START]->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'a', "first letter is 'a'");

ok($letter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_NEXT]->[LETTER__DATA_PAYLOAD] eq 'b', "a next connects to b");
ok(not(defined($letter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_PREV]->[LETTER__DATA_PAYLOAD])),  "a prev connects to nothing");

$letter = $letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'b', "next letter is b");
ok($letter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_NEXT]->[LETTER__DATA_PAYLOAD] eq 'c', "b next connects to c");
ok($letter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_PREV]->[LETTER__DATA_PAYLOAD] eq 'a', "b prev connects to a");

$letter = $letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'c', "next letter is c");
ok($letter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_NEXT]->[LETTER__DATA_PAYLOAD] eq 'd', "c next connects to d");
ok($letter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_PREV]->[LETTER__DATA_PAYLOAD] eq 'b', "c prev connects to b");

$letter = $letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'd', "next letter is d");
ok(not(defined($letter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_NEXT]->[LETTER__DATA_PAYLOAD])), "d next connects to nothing");
ok($letter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_PREV]->[LETTER__DATA_PAYLOAD] eq 'c', "d prev connects to c");

$letter = $letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'LASTSTART', "last letter is LASTSTART marker");

__DATA__

This test is doing basic checks for creating a one-dimensional string.


Dumping LinkedList object
LETPKG => Parse::Gnaw::Blocks::Letter # package name of letter objects
CONNMIN1 => 0 # max number of connections, minus 1
HEADING_DIRECTION_INDEX => 0
HEADING_PREVNEXT_INDEX  => 0
FIRSTSTART => 

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8737798)
	payload: 'FIRSTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]

LASTSTART => 

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x87375b8)
	payload: 'LASTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]

CURRPTR => 

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8737798)
	payload: 'FIRSTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]


letters, by order of next_start_position()

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8924520)
	payload: 'a'
	from: file t/llist_create_1d_parseconnections.t, line 25, column 0
	connections:
		 [ ........... , (0x89245d4) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x89245d4)
	payload: 'b'
	from: file t/llist_create_1d_parseconnections.t, line 25, column 1
	connections:
		 [ (0x8924520) , (0x89246ec) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x89246ec)
	payload: 'c'
	from: file t/llist_create_1d_parseconnections.t, line 25, column 2
	connections:
		 [ (0x89245d4) , (0x8924804) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x8924804)
	payload: 'd'
	from: file t/llist_create_1d_parseconnections.t, line 25, column 3
	connections:
		 [ (0x89246ec) , ........... ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x87375b8)
	payload: 'LASTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]




