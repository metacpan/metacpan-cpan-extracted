#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    plan skip_all => "Author tests not required for installation" unless $ENV{RELEASE_TESTING};

    plan skip_all => "\$ENV{SKIP_POD_LINKCHECK} is set, skipping tests" if $ENV{SKIP_POD_LINKCHECK};

    eval "use Test::Pod::LinkCheck";
    plan skip_all => "Test::Pod::LinkCheck required to test POD for broken links" if $@;
}

Test::Pod::LinkCheck->new()->all_pod_ok();
