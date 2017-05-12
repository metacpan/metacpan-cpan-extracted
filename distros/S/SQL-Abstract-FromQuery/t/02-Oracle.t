use strict;
use warnings;
use Test::More;

use Module::Load;
load 'SQL::Abstract::FromQuery';


my $parser = SQL::Abstract::FromQuery->new(-components => [qw/Oracle/]);


my %tests = (
# test_name      => [$given, $expected]
# =========         ===================

  date           => ['1.2.03',
                     \ ["to_date(?, 'YYYY-MM-DD')", '2003-02-01']
                    ],

  time           => ['1:02',
                     \ ["to_date(?, 'HH24:MI:SS')", '01:02:00']
                    ],

);

my %data = map {$_ => $tests{$_}[0]} keys %tests;

plan tests => scalar keys %data;


my $where = $parser->parse(\%data);

while (my ($test_name, $test_data) = each %tests) {
  is_deeply($where->{$test_name}, $test_data->[1], $test_name);
}



