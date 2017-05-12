#!/usr/bin/perl -w

use strict;

use Test::More tests => 12;

BEGIN {
    use_ok('RFID::Reader');
    use_ok('RFID::Tag');
};

# To test an abstract base class, we have to play some games.
my $reader = bless {}, 'RFID::Reader';
ok($reader);

ok($reader->_init);

my $t1 = bless {}, 'RFID::Tag';
$t1->_init(id => 'abc');
my $t2 = bless {}, 'RFID::Tag';
$t2->_init(id => 'def');
my $t3 = bless {}, 'RFID::Tag';
$t3->_init(id => 'def');
my $t4 = bless {}, 'RFID::Tag';
$t4->_init(id => 'abc');
my @tags = ($t1,$t2,$t3,$t4);
ok($t1 and $t2 and $t3 and $t4 and @tags);

ok($reader->get('UniqueTags')==0);
ok($reader->filter_tags(@tags)==@tags);

ok($reader->set(UniqueTags => 1)==0);
ok($reader->get('UniqueTags')==1);
ok($reader->filter_tags(@tags)==@tags/2);

ok($reader->set(NoSuchVariable => 77) == 1);
ok(!defined($reader->get('NoSuchVariable')));


