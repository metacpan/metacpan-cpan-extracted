#!perl
use strict;
use warnings;
use Test::More tests => 6;
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
