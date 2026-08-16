#!perl

# Keeps MANIFEST honest in both directions. CONTRIBUTING.md was added to the
# repository but never to MANIFEST, so it silently stayed out of the released
# tarball; this catches that class of drift.

use strict;
use warnings;
use Test::More;

plan skip_all => 'Author test; set AUTHOR_TESTING=1 to run'
    unless $ENV{AUTHOR_TESTING};

require ExtUtils::Manifest;

my @missing = ExtUtils::Manifest::manicheck();
is_deeply( \@missing, [], 'every file in MANIFEST exists on disk' )
    or diag "listed but absent: @missing";

my @unlisted = ExtUtils::Manifest::filecheck();
is_deeply( \@unlisted, [], 'every shippable file is listed in MANIFEST' )
    or diag "present but unlisted: @unlisted";

done_testing;
