#!/usr/bin/perl -w

use strict;

use Test::More tests => 16;

BEGIN {
    use_ok('RFID::Tag');
};

# To test an abstract base class, we have to play some games.

my $tag1 = bless {}, 'RFID::Tag';
ok($tag1);
$tag1->_init(ID => 12345, Antenna => '77', Location => 'My Office', time => time);
ok($tag1->get('Type') eq 'unknown');
my %t1p = $tag1->get(qw(id aNTENNA lOCATION TIME));
ok(%t1p);
ok($t1p{id} == 12345);
ok($t1p{aNTENNA} eq '77');
ok($t1p{lOCATION} eq 'My Office');
ok($t1p{TIME});

ok($tag1->id == 12345);

ok(!defined($tag1->get('NoSuchVariable')));

# Test out tagcmp
ok($tag1->tagcmp($tag1)==0);

my $tag2 = bless {}, 'RFID::Tag';
$tag2->_init(id => '23456');
ok($tag1->tagcmp($tag2)==-1);

my $tag3 = bless {}, 'RFID::Tag';
$tag3->_init(id => '01234');
ok($tag1->tagcmp($tag3)==1);

my $tag4 = bless {}, 'RFID::Tag';
$tag4->_init(id => '12345');
ok($tag1->tagcmp($tag4)==0);

my @sorted = sort { $a->tagcmp($b) } ($tag1, $tag2, $tag3, $tag4);
ok(@sorted);
ok($sorted[0]->id eq '01234' 
   and $sorted[1]->id eq '12345' 
   and $sorted[2]->id eq '12345'
   and $sorted[3]->id eq '23456');


