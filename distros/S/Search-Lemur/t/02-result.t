use warnings;
use strict;

use Test::Simple tests => 3;
use Data::Dumper;

use Search::Lemur;

# test result methods

my $result1 = Search::Lemur::Result->_new("sggjf", 0, 0);
my $result2 = Search::Lemur::Result->_new("sggjf", 0, 0);
my $result3 = Search::Lemur::Result->_new("test", 5, 1);
my $result4 = Search::Lemur::Result->_new("test", 5, 1);
my $item7 = Search::Lemur::ResultItem->_new(3245, 54, 5);
$result3->_add($item7);
$result4->_add($item7);
      
# equals
ok($result1->equals($result2), "empty result equals test");
ok($result3->equals($result4), "nonempty result equals test");
ok(!($result2->equals($result4)), "nonempty/empty result equals test");

