use strict;
use warnings;
use Test::More;

use SQL::Abstract::FromQuery;
use UNIVERSAL::DOES  qw/does/;
use Try::Tiny;

diag( "Testing SQL::Abstract::FromQuery "
    . "$SQL::Abstract::FromQuery::VERSION, Perl $], $^X" );

my $have_cgi = eval { require CGI; 1; } || 0;

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
  greater_date   => ['> 1.2.03',
                     {'>' => '2003-02-01'}],
  time           => ['1:02',
                     '01:02:00'],
  datetime       => ['2003-02-01 4:05:06',
                     '2003-02-01T04:05:06'],
  datetime_iso   => ['2003-02-01T04:05:06',
                     '2003-02-01T04:05:06'],
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
  initial_space  => [' a z',
                     'a z'],
  trailing_space => ['a z ',
                     'a z'],
  regexp         => ['/^a/im',
                     {-regexp => ['^a', 'im']}],
  no_regexp      => ['P/123/2017',
                     'P/123/2017'],
  quoted_regexp  => ['"/^a/"',
                     '/^a/'],
  foo_ignore     => ['BETWEEN ! - %*"', # will be IGNOREd
                     undef],

);

plan tests => @tests / (2 - $have_cgi);

while (my ($test_name, $test_data) = splice(@tests, 0, 2)) {
  my ($given, $expected) = @$test_data;

  for my $i (0 .. $have_cgi) {
    my ($where, $parse_arg);
    $parse_arg = {$test_name => $given};
    if ($i) {
      no warnings 'once';
      $CGI::LIST_CONTEXT_WARN = 0;
      $parse_arg = CGI->new ($parse_arg);
    }
    try   {$where = $parser->parse($parse_arg)}
    catch {$where = {DIED => $_}; };

    if (does($expected, 'HASH') && $expected->{DIE}) {
      like $where->{DIED} || $where->{$test_name}, $expected->{DIE}, $test_name;
    }
    else {
      is_deeply($where->{$test_name} || $where->{DIED}, $expected, $test_name);
    }
  }
}
