use strict;
use utf8;
use warnings;

BEGIN {
  binmode STDOUT, ":utf8";
  binmode STDERR, ":utf8";
}

use Test::More;
use Test::NoWarnings;
use Net::IDN::UTS46 ":all";

no warnings "utf8";

my @labels = (
  ["a" . chr(0x110000), qr/disallowed character U\+110000 \[V6\]/,
    "a code point above U+10FFFF"],
  ["a" . chr(0xD800), qr/disallowed character U\+D800/, "a surrogate"],
);

plan tests => 1 + 8 * @labels;

for my $test (@labels) {
  my ($label, $message, $comment) = @$test;

  for my $allow (0, 1) {
    is eval { uts46_to_ascii($label, AllowUnassigned => $allow) }, undef,
      "to_ascii rejects $comment (AllowUnassigned => $allow)";
    like $@, $message, "to_ascii names $comment";

    is eval { uts46_to_unicode($label, AllowUnassigned => $allow) }, undef,
      "to_unicode rejects $comment (AllowUnassigned => $allow)";
    like $@, $message, "to_unicode names $comment";
  }
}
