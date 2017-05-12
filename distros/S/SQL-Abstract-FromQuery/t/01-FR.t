use strict;
use warnings;
use Test::More;

use Module::Load;
load 'SQL::Abstract::FromQuery';

my $parser = SQL::Abstract::FromQuery->new(
  -components => [qw/FR/],
  -fields => {
     bool => [qw/bool_oui bool_non/],
   },
 );


my %tests = (
# test_name      => [$given, $expected]
# =========         ===================

  null           => ['NULL',
                     {'=' => undef}
                    ],
  null_FR        => ['NUL',
                     {'=' => undef}
                    ],
  not_null_FR    => ['!NUL',
                     {'<>' => undef}
                    ],
  bool_oui       => ['OUI',
                     1],
  bool_non       => ['N',
                     0],
  between        => ['BETWEEN a AND z',
                     {-between => [qw/a z/]}],
  between_FR     => ['ENTRE a ET z',
                     {-between => [qw/a z/]}],

);


my %data = map {$_ => $tests{$_}[0]} keys %tests;

plan tests => scalar keys %data;

my $where = $parser->parse(\%data);

while (my ($test_name, $test_data) = each %tests) {
  is_deeply($where->{$test_name}, $test_data->[1], $test_name);
}
