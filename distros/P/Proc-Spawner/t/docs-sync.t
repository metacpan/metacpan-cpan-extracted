# The documents in line with what they show (doc/docs-sync.pl; make docs-check).  Only for a release
# (RELEASE_TESTING=1): a document that needs bringing in line by hand never fails an installation.
use strict; use warnings; use Test::More;
plan skip_all => 'set RELEASE_TESTING=1 (make docs-check)' unless $ENV{RELEASE_TESTING};
my $out = `$^X doc/docs-sync.pl check 2>&1`;
is($? >> 8, 0, 'every part of the documents is in line with its inputs') or diag $out;
done_testing;
