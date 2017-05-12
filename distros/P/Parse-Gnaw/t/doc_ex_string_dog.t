#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;
use Test::More;

plan tests => 1;

use lib 'lib';

use Parse::Gnaw;
use Parse::Gnaw::LinkedList;
use Parse::Gnaw::LinkedListConstants;
use Parse::Gnaw::Blocks::LetterConstants;
use Parse::Gnaw::LinkedListDimensions1;

my $string=Parse::Gnaw::LinkedListDimensions1->new("dog");
$string->display();

my $letter=$string->[LIST__CURR_START]->[LETTER__NEXT_START];
ok($letter->[LETTER__DATA_PAYLOAD] eq 'd', "check letter is payload");

