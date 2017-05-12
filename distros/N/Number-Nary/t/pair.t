use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok(
    'Number::Nary',
    -codec_pair => { digits => '0123456789ABC', -suffix => 13 }
  );
}

my $meaning = encode13(6 * 9);

is($meaning, "42", "encodes base 13 properly");

my $meaningless = decode13($meaning);

is($meaningless, "54", "decodes base 13 properly");
