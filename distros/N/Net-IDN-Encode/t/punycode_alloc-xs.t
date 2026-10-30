use strict;
use warnings;

use Config;

use Test::More;
use Net::IDN::Punycode ();
use Net::IDN::Punycode::PP ();

BEGIN {
  plan skip_all => 'no XS version' if eval {
    \&Net::IDN::Punycode::decode_punycode ==
    \&Net::IDN::Punycode::PP::decode_punycode; }
}

our $LEN;

BEGIN {
  # the code point buffer size wraps STRLEN on a 32-bit perl, so only an
  # input past the wrap point reaches the guard in either function. That
  # is why this test needs 1GB and skips everywhere else.
  plan skip_all => 'needs a 32-bit address space' if $Config{ptrsize} != 4;

  $LEN = 2**30;

  my $free = 0;
  if (open my $meminfo, "<", "/proc/meminfo") {
    my ($kb) = map /^MemAvailable:\s+(\d+)/, <$meminfo>;
    $free = ($kb || 0) * 1024;
  }

  # a cgroup caps a container, whilst /proc/meminfo shows the host
  for my $cap ("/sys/fs/cgroup/memory.max",
      "/sys/fs/cgroup/memory/memory.limit_in_bytes")
  {
    open my $fh, "<", $cap or next;
    chomp(my $bytes = <$fh>);
    $free = $bytes if $bytes && $bytes =~ /^\d+$/ && $bytes < $free;
  }

  plan skip_all => "needs ".int($LEN / 2**20)."MB of free memory"
    if $free < $LEN * 1.2;
}

use Test::NoWarnings;

plan tests => 7;

my $label = "\xFF" x $LEN;

is(eval { Net::IDN::Punycode::decode_punycode($label) }, undef,
  "validation comes before the size guard (dies)");
like($@, qr/non-base character/,
  "validation comes before the size guard (message)");

$label =~ tr/\xFF/a/;    # in place, to hold one buffer only
substr($label, -1, 1, "-");

is(eval { Net::IDN::Punycode::decode_punycode($label) }, undef,
  "the code point buffer size wraps STRLEN (dies)");
like($@, qr/input too long/,
  "the code point buffer size wraps STRLEN (message)");

substr($label, -1, 1, "a");
utf8::upgrade($label);    # sets the flag in place on an ASCII string

is(eval { Net::IDN::Punycode::encode_punycode($label) }, undef,
  "the encoder buffer size wraps STRLEN (dies)");
like($@, qr/input too long/,
  "the encoder buffer size wraps STRLEN (message)");
