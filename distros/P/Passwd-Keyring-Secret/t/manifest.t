#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    plan skip_all => "Author tests not required for installation" unless $ENV{RELEASE_TESTING};

    eval "use Test::CheckManifest 0.9";
    plan skip_all => "Test::CheckManifest 0.9 required for testing MANIFEST" if $@;
}

ok_manifest();
