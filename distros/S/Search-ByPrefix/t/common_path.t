#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

use Search::ByPrefix;
my $obj = Search::ByPrefix->new;

foreach my $pair (
                  [["", "home", "user1", "tmp",  "coverage", "test"],     "/home/user1/tmp/coverage/test"],
                  [["", "home", "user1", "tmp",  "covert",   "operator"], "/home/user1/tmp/covert/operator"],
                  [["", "home", "user1", "tmp",  "coven",    "members"],  "/home/user1/tmp/coven/members"],
                  [["", "home", "user1", "tmp2", "coven",    "members"],  "/home/user1/tmp2/coven/members"],
                  [["", "home", "user2", "tmp",  "coven",    "members"],  "/home/user2/tmp/coven/members"],
  ) {
    $obj->add(@{$pair});
}

# Finds the directories that have this common path
my @values = $obj->search(['', 'home', 'user1', 'tmp']);

my @expect = qw(
  /home/user1/tmp/coverage/test
  /home/user1/tmp/covert/operator
  /home/user1/tmp/coven/members
  );

is($#values, $#expect);

foreach my $i(0..$#expect) {
    is($values[$i], $expect[$i]);
}
