
use strict;
use Test::More tests => 1;
use Net::SenderBase;

# This test checks all the invalid ways to construct a query

eval {
    Net::SenderBase::Query->new();
};
ok($@, "Check no params works");

