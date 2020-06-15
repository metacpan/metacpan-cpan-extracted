#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Search::ByPrefix;
my $obj = Search::ByPrefix->new;

sub make_key {
    my ($str) = @_;
    [split(m{/}, $str)];
}

foreach my $path (
                  "/home/user1/tmp/coverage/test",
                  "/home/user1/tmp/covert/operator",
                  "/home/user1/tmp/coven/members",
                  "/home/user1/tmp/coven/members",
                  "/home/user1/tmp2/coven/members",
                  "/home/user2/tmp/coven/members",
                  "/home/user1/values/secret",
                  "/home/user2/values/secret",
                  "/home/user1/tmp/values/secret",
                  "/home/user1/tmp/values/secret",
                  "/home/user1/tmp/values/secret",
  ) {
    my $key = make_key($path);
    $obj->add($key, $path);
}



# Finds the directories that have this common path
my @values = $obj->search(make_key("/home/user1/tmp"));

my @expect = qw(
  /home/user1/tmp/coverage/test
  /home/user1/tmp/covert/operator
  /home/user1/tmp/coven/members
  /home/user1/tmp/coven/members
  /home/user1/tmp/values/secret
  /home/user1/tmp/values/secret
  /home/user1/tmp/values/secret
  );

is_deeply(\@values, \@expect);
