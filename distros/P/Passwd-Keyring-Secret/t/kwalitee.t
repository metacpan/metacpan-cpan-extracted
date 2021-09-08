#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    plan skip_all => "Author tests not required for installation" unless $ENV{RELEASE_TESTING};

    eval "use Test::Kwalitee qw(kwalitee_ok)";
    plan skip_all => "Test::Kwalitee required for testing quality" if $@;
}

kwalitee_ok();

done_testing();
