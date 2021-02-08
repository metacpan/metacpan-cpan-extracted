use strict;
use warnings;
use Test::More;

use SQL::Abstract::FromQuery;
use SQL::Abstract::FromQuery::Oracle;

my $parser = SQL::Abstract::FromQuery->new(-components => [qw/Oracle/]);

my $dt_fmt = $SQL::Abstract::FromQuery::Oracle::datetime_fmt_ISO;
my $t_fmt  = $SQL::Abstract::FromQuery::Oracle::time_fmt;



my %tests = (
# test_name      => [$given, $expected]
# =========         ===================

  date           => ['1.2.03',
                     \ ["= TO_DATE(?, '$dt_fmt')", '2003-02-01']
                    ],

  greater_date   => ['> 1.2.03',
                     {'>' => \ ["TO_DATE(?, '$dt_fmt')", '2003-02-01'] }],


  between_dates  => ['BETWEEN 01.02.03 AND 04.05.06',
                     {-between => [ \["TO_DATE(?, '$dt_fmt')", '2003-02-01'],
                                    \["TO_DATE(?, '$dt_fmt')", '2006-05-04'] ] }],

  time           => ['1:02',
                     \ ["= TO_DATE(?, '$t_fmt')", '01:02:00']
                    ],

  datetime       => ['01.02.2003 12:34',
                     \ ["= TO_DATE(?, '$dt_fmt')", '2003-02-01T12:34:00']
                    ],



);

my %data = map {$_ => $tests{$_}[0]} keys %tests;

plan tests => scalar keys %data;

my $where = $parser->parse(\%data);
while (my ($test_name, $test_data) = each %tests) {
  is_deeply($where->{$test_name}, $test_data->[1], $test_name);
}



