#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;


use Test::More;

plan tests => 8;


use lib 'lib';

use Parse::Gnaw::LinkedListDimensions2;
use Parse::Gnaw::LinkedListConstants;
use Parse::Gnaw::Blocks::Letter;
use Parse::Gnaw::Blocks::LetterConstants;

# we're going to construct a basic 2-dimensional string linked list to parse
# but we're not going to run a grammar on it.
# we're just going to see that the 2D linked list got created correctly.

my $raw_2d_string=<<'RAWSTRING';
abcd
efgh
ijkl
mnop
RAWSTRING

my $string=Parse::Gnaw::LinkedListDimensions2->new(string=>$raw_2d_string);


print $string->display; 


ok($string->[LIST__FIRST_START]->[1]    eq 'FIRSTSTART', "first is first"  );
ok($string->[LIST__LAST_START]->[1]     eq 'LASTSTART' , "last is last"    );
ok($string->[LIST__CURR_START]->[1]     eq 'FIRSTSTART', "current is first");


my $letter=$string->[LIST__CURR_START]->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'a', "first letter is 'a'");

for my $i (1..6){
	$letter=$letter->[LETTER__NEXT_START];
}
ok($letter->[LETTER__DATA_PAYLOAD] eq 'g', "follow next start a while and letter is 'g'");

for my $i (1..6){
	$letter=$letter->[LETTER__NEXT_START];
}
ok($letter->[LETTER__DATA_PAYLOAD] eq 'm', "follow next start a while and letter is 'm'");


for my $i (1..3){
	$letter=$letter->[LETTER__NEXT_START];
}
ok($letter->[LETTER__DATA_PAYLOAD] eq 'p', "follow next start a while and letter is 'p'");

$letter=$letter->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'LASTSTART', "follow next start a while and letter is 'LASTSTART'");






