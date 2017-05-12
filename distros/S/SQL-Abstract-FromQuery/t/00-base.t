use strict;
use warnings;
use Test::More;

use SQL::Abstract::FromQuery;
use UNIVERSAL::DOES  qw/does/;
use Try::Tiny;

diag( "Testing SQL::Abstract::FromQuery "
    . "$SQL::Abstract::FromQuery::VERSION, Perl $], $^X" );

my $parser = SQL::Abstract::FromQuery->new(
  -fields => {IGNORE => qr/^foo/},
);

my @tests = (
# test_name      => [$given, $expected]
# =========         ===================
  regular        => ['foo',
                     'foo'],
  list           => ['foo,bar, buz',
                     {-in => [qw/foo bar buz/]}],
  neg            => ['!foo',
                     {'<>' => 'foo'}],
  neg_list       => ['!foo,bar,buz',
                     {-not_in => [qw/foo bar buz/]}],
  neg_minus      => ['-foo',
                     {'<>' => 'foo'}],
  bad_neg        => ['!',
                     {DIE => qr/value after negation/}],
  num            => ['-123',
                     -123],
  between        => ['BETWEEN a AND z',
                     {-between => [qw/a z/]}],
  between_nums   => ['BETWEEN -2 AND 3',
                     {-between => [qw/-2 3/]}],
  bad_between    => ['BETWEEN ! - %*"',
                     {DIE => qr/Expected min and max/}],
  between_typo   => ['BETWEEN a ANND z',
                     {DIE => qr/Expected min and max/}],
  between_silly  => ['BETWEEN a AND b AND c',
                     {-between => ['a', 'b AND c']}],
  pattern        => ['foo*',
                     {-like => 'foo%'}],
  greater        => ['> foo',
                     {'>' => 'foo'}],
  greater_or_eq  => ['>= foo',
                     {'>=' => 'foo'}],
  null           => ['NULL',
                     {'=' => undef}],
  not_null       => ['!NULL',
                     {'<>' => undef}],
  date_dash      => ['03-2-1',
                     '2003-02-01'],
  date_dot       => ['1.2.03',
                     '2003-02-01'],
  time           => ['1:02',
                     '01:02:00'],
  double_quoted  => ['"foo  bar"',
                     'foo  bar'],
  single_quoted  => ["'foo  bar'",
                     'foo  bar'],
  quoted_list    => ["'foo,bar',buz",
                     {-in => ['foo,bar', 'buz']}],
  two_words      => ['a z',
                     'a z'],
  double_space   => ['a  z',
                     'a  z'],
  initial_space   => [' a z',
                      'a z'],
  trailing_space  => ['a z ',
                      'a z'],

  foo_ignore     => ['BETWEEN ! - %*"', # will be IGNOREd
                     undef],

);

plan tests => @tests / 2;

while (my ($test_name, $test_data) = splice(@tests, 0, 2)) {
  my ($given, $expected) = @$test_data;

  my $where;
  try   {$where = $parser->parse({$test_name => $given})}
  catch {$where = {DIED => $_}; };

  if (does($expected, 'HASH') && $expected->{DIE}) {
    like $where->{DIED} || $where->{$test_name}, $expected->{DIE}, $test_name;
  }
  else {
    is_deeply($where->{$test_name} || $where->{DIED}, $expected, $test_name);
  }
}


