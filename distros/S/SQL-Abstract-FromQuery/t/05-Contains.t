use strict;
use warnings;
use Test::More;

use Module::Load;
load 'SQL::Abstract::FromQuery';

my $parser = SQL::Abstract::FromQuery->new(
  -components => [qw/Contains/],
  -fields => {
     contains => [qw/fulltext/],
   },
);

my %tests = (
# test_name      => [$given, $expected]
# =========         ===================

  fulltext       => [ 'foo bar, buz',
                      {-contains => [qw/foo bar buz/]},
                    ],
);

my %data = map {$_ => $tests{$_}[0]} keys %tests;

plan tests => scalar keys %data;


my $where = $parser->parse(\%data);

while (my ($test_name, $test_data) = each %tests) {
  is_deeply($where->{$test_name}, $test_data->[1], $test_name);
}



