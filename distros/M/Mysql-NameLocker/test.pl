#!/usr/bin/perl -w
use strict;
use lib qw(lib);
use Test;

BEGIN {
 plan tests => 1;
}
eval {require Mysql::NameLocker;};
ok($@ ? 0 : 1);