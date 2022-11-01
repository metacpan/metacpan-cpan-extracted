#!perl
use strict;
use warnings;
use Test::More;
use String::Flogger qw(flog);

is(
  flog([ 'foo %s bar', undef ]),
  'foo {{null}} bar',
  "%s <- undef",
);

is(
  flog([ 'foo %s bar', \undef ]),
  'foo ref({{null}}) bar',
  "%s <- \\undef",
);

is(
  flog([ 'foo %s bar', \1 ]),
  'foo ref(1) bar',
  "%s <- \\1",
);

is(
  flog([ 'foo %s bar', \\1 ]),
  'foo ref(ref(1)) bar',
  "%s <- \\\\1",
);

like(
  flog({foo => 'bar'}),
  qr/foo.+bar/,
  "hashref keys/values printed",
);

like(
  flog(sub { +{foo => 'bar'} }),
  qr/foo.+bar/,
  "hashref keys/values printed",
);

my $object = bless {}, 'String::Flogger::Test';

like(
  flog([ 'an object: %s', $object ]),
  qr/\Aan object: obj\(String::Flogger::Test=HASH\(0x[[:xdigit:]]+\)\)\z/,
  "an object in the output",
);

like(
  flog([ 'an object: %s', [$object] ]),
  qr/\Aan object: \{\{\["obj\(String::Flogger::Test=HASH\(0x[[:xdigit:]]+\)\)"\]}}\z/,
  "an object in an array in the output",
);

done_testing;
