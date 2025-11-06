use Test2::V0;
use Test::Alien;
use Neo4j::Client;

BEGIN {
  require Alien::OpenSSL;
  diag('Alien::OpenSSL package version ' . Alien::OpenSSL->version);
}

alien_ok 'Neo4j::Client';
my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  my($mod) = @_;

  ok my $openssl_version = $mod->neo4j_openssl_version(0);
  diag($mod->neo4j_openssl_version($_)) for 0, 4, 5;
};

done_testing;

# This test relies on a patch made by nc-update to lib/src/openssl.c.
# The point is to verify that both Omni and OpenSSL are linked correctly.
# As a bonus, we get diagnostic output of the OpenSSL version number.

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <neo4j-client.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *
neo4j_openssl_version(class, int t)
  C_ARGS: t
