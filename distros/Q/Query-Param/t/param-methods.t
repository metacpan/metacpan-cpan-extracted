use strict;
use warnings;

use Test::More;
use Query::Param;

########################################################################
subtest 'param() method' => sub {
########################################################################
  my $q = Query::Param->new("foo=1&bar=2&bar=3&empty=&encoded=%25+%2B");

  is_deeply( [ sort $q->param ], [ sort qw(foo bar empty encoded) ], 'param() returns all keys' );

  is( $q->param('foo'), '1', 'param(foo) returns scalar' );
  is_deeply( $q->param('bar'), [ '2', '3' ], 'param(bar) returns arrayref of values' );
  is( $q->param('empty'),   q{},   'param(empty) returns empty string' );
  is( $q->param('encoded'), '% +', 'param(encoded) returns correct decoded value' );
};

########################################################################
subtest 'params() method' => sub {
########################################################################
  my $q = Query::Param->new("foo=1&bar=2&bar=3&empty=&encoded=%25+%2B");

  my $expected = {
    foo     => '1',
    bar     => [ '2', '3' ],
    empty   => q{},
    encoded => '% +',
  };

  is_deeply( $q->params, $expected, 'params() returns full decoded hashref' );
};

done_testing();

1;
