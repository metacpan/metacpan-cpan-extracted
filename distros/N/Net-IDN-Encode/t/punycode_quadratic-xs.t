use strict;
use warnings;

use Test::More;
use Net::IDN::Punycode ();
use Net::IDN::Punycode::PP ();

BEGIN {
  plan skip_all => 'no XS version' if eval {
    \&Net::IDN::Punycode::decode_punycode ==
    \&Net::IDN::Punycode::PP::decode_punycode; }
}

use Test::NoWarnings;

my $front = join "", map chr(0x80 + $_), reverse 0 .. 1999;

our @large = (
  ["a" x 200000, chr(0x80) x 200000, "a label of single-digit code points"],
  [Net::IDN::Punycode::encode_punycode($front), $front,
    "a label inserting every code point at the front"],
);

plan tests => 1
  + 1 * (scalar @large);

foreach my $test (@large)
{
  my ($label, $expected, $comment) = @{$test};

  SKIP: {
    my $pid = fork;
    skip 'cannot fork', 1 if !defined $pid;

    if (!$pid) {
      close STDERR;
      $SIG{__WARN__} = sub {};	# Test::NoWarnings keeps a backtrace per warning
      alarm 10;
      my $got = eval { Net::IDN::Punycode::decode_punycode($label) };
      exit(defined $got && $got eq $expected ? 0 : 1);
    }

    waitpid($pid, 0);
    is($?, 0, $comment.' (decode_punycode keeps up)');
  }
}
