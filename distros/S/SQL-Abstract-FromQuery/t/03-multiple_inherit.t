use strict;
use warnings;
use Test::More;

use SQL::Abstract::FromQuery;
use SQL::Abstract::FromQuery::Oracle;


my $dt_fmt = $SQL::Abstract::FromQuery::Oracle::datetime_fmt_ISO;

my $parser = SQL::Abstract::FromQuery->new(
  -components => [qw/FR Oracle/],
  -fields => {
     bool => [qw/bool_oui/],
   },
);

my %tests = (
# test_name      => [$given, $expected]
# =========         ===================

  date           => ['1.2.03',
                     \ ["= TO_DATE(?, '$dt_fmt')", '2003-02-01']
                    ],
  bool_oui       => ['OUI',
                     1],

);

my %data = map {$_ => $tests{$_}[0]} keys %tests;

plan tests => scalar keys %data;


my $where = $parser->parse(\%data);

while (my ($test_name, $test_data) = each %tests) {
  is_deeply($where->{$test_name}, $test_data->[1], $test_name);
}



