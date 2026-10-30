use strict;
use warnings;

use Test::More;
use Net::IDN::Punycode ();
use Net::IDN::Punycode::PP ();

sub rss_kb {
  no warnings 'exec';
  my $out = `ps -o rss= -p $$`;
  return defined $out && $out =~ /(\d+)/ ? $1 : undef;
}

BEGIN {
  plan skip_all => 'no XS version' if eval {
    \&Net::IDN::Punycode::decode_punycode ==
    \&Net::IDN::Punycode::PP::decode_punycode; };
  plan skip_all => 'cannot read resident set size via ps' if !rss_kb();
}

use Test::NoWarnings;

no warnings 'utf8';    # perl 5.12 and older warn on the fixture below

# chr(0xFFFFFFFF) is fatal where ivsize is 4, so build it at runtime
my $max_uv32 = eval { my $cp = 0xFFFFFFFF; chr $cp };

our @rejections = (
  (defined $max_uv32
    ? [("a" x 2000).$max_uv32, \&Net::IDN::Punycode::encode_punycode,
        "rejected encode input"]
    : ()),
  [("a" x 2000)."\xFF", \&Net::IDN::Punycode::decode_punycode,
    "rejected decode input"],
);

plan tests => 1
  + 1 * (scalar @rejections);

foreach my $test (@rejections)
{
  my ($input, $function, $comment) = @{$test};

  eval { $function->($input) } for 1 .. 1000;
  my $before = rss_kb();
  eval { $function->($input) } for 1 .. 25000;
  my $growth = rss_kb() - $before;

  cmp_ok($growth, '<', 10240,
    $comment.' does not leak memory ('.$growth.' KiB over 25000 calls)');
}
