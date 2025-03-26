use utf8;
use Test2::V0;
use Data::Dumper;
use DateTime::Format::ISO8601;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $input = q{
datetime=2020-05-04T16:37:02.905408062+01:00
datetimes="2020-05-04T16:37:02.905408062+01:00"
float=3.14
floats="3.14"
uint=3
uints="3"
nint=-4
nints="-4"
bigint=1852528528562625752750
bigints="1852528528562625752750"
hex=0x12
oct=0o751
bin=0b11010110
boolf=false
boolt=true
boolfs="false"
boolts="true"
dtlocal=1979-05-27T00:32:00.643144312
dtlocals="1979-05-27T00:32:00.643144312"
};

sub norm ($) {
  join "\n", (
    sort
    map {
      s{=0o(\d+)$}{ '='.oct($1) }e;
      s{=(0[xb]\w+)$}{ '='.eval($1) }e;
      $_;
    }
    grep /./,
    split /\n/, $_[0]
  ), ''
}

my $coder = TOML::Tiny->new(
  no_string_guessing => 1,
  inflate_datetime => sub {
    # RFC3339 bombs out if there is no timezone, so we parse with 8601
    DateTime::Format::ISO8601->parse_datetime(shift)
  },
);

my $parsed = $coder->decode($input);
my $actual = norm($coder->encode($parsed));
my $expected = norm($input);

is($actual, $expected, 'round trip') or do{
  diag 'EXPECTED:';
  diag Dumper($expected);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

done_testing;
