use warnings;
use strict;

use Test::Simple tests => 11;
use Data::Dumper;

use Search::Lemur;

# test resultItem methods
# 
# test equals methods:
my $item1 = Search::Lemur::ResultItem->_new(1, 12, 3);
my $item2 = Search::Lemur::ResultItem->_new(1, 12, 3);
my $item3 = Search::Lemur::ResultItem->_new(2, 12, 3);
my $item4 = Search::Lemur::ResultItem->_new(1, 13, 3);
my $item5 = Search::Lemur::ResultItem->_new(1, 12, 4);
my $item6 = Search::Lemur->new("blah");

ok($item1->equals($item2), "resultItem equals true check1");
ok(!($item1->equals($item3)), "resultItem equals false check 1");
ok(!($item1->equals($item4)), "resultItem equals false check 2");
ok(!($item1->equals($item5)), "resultItem equals false check 3");
ok(!($item1->equals($item6)), "resultItem equals false check 4");

# check docid()
ok($item1->docid() == 1, "resultItem docid() test");
ok($item3->docid() == 2, "resultItem docid() test");

# check doclen()
ok($item1->doclen() == 12, "resultItem docid() test");
ok($item4->doclen() == 13, "resultItem docid() test");

#check tf()
ok($item1->tf() == 3, "resultItem tf() test");
ok($item5->tf() == 4, "resultItem tf() test");


