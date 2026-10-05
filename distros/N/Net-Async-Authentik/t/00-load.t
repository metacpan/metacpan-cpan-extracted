#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Net::Async::Authentik
  Net::Async::Authentik::API
  Net::Async::Authentik::Error
  Net::Async::Authentik::Error::API
  Net::Async::Authentik::Error::Network
  Net::Async::Authentik::Error::Validation
  Net::Async::Authentik::OIDC
  Net::Async::Authentik::Role::HTTP
)) {
  use_ok($_);
}

# t/lib/FakeAuthentik.pm is a copy of the synchronous distribution's, because
# a test file cannot be pulled in as a dependency. When that checkout is next
# door, the two must still be the same file.
my $sync = $ENV{WWW_AUTHENTIK_DIR} || "$ENV{HOME}/dev/p5-www-authentik";
SKIP: {
  skip 'the synchronous distribution is not checked out next door', 1
    unless -f "$sync/t/lib/FakeAuthentik.pm";
  my $here  = do { local ( @ARGV, $/ ) = 't/lib/FakeAuthentik.pm'; <> };
  my $there = do { local ( @ARGV, $/ ) = "$sync/t/lib/FakeAuthentik.pm"; <> };
  # the header comment differs on purpose, everything from `use strict` must not
  my $body = sub { $_[0] =~ s/\A.*?^use strict;/use strict;/smr };
  is( $body->($here), $body->($there), 'the fake authentik has not drifted from the synchronous distribution' );
}

done_testing;
