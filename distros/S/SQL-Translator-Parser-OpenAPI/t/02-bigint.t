use strict;
use warnings;
use Test::More 0.98;
use Math::BigInt;

use_ok 'SQL::Translator::Parser::OpenAPI', 'defs2mask';

# properties:
my $defs = {
  d1 => {
    properties => {
      p1 => 'string',
      p2 => 'string',
    },
  },
  d2 => {
    properties => {
      p2 => 'string',
      p3 => 'string',
    },
  },
};
my $mask = SQL::Translator::Parser::OpenAPI::defs2mask($defs);
# all prop names, sorted: qw(p1 p2 p3)
# $mask:
my $expected = {
  d1 => (1 << 0) | (1 << 1),
  d2 => (1 << 1) | (1 << 2),
};
is_deeply $mask, $expected, 'basic mask check';

$defs = +{ map {
  my $defcount = $_;
  (
    sprintf("d%02d", $defcount) => { properties => {
      map { (sprintf("p%03d", $_ + $defcount) => 'string') } (1..3)
    } }
  )
} (1..70) };
$mask = SQL::Translator::Parser::OpenAPI::defs2mask($defs);
is $mask->{d68} & $mask->{d70}, Math::BigInt->new(1) << 69,
  'bigint-needing mask check';

done_testing;
