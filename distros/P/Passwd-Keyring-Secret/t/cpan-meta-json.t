#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    eval "use Test::CPAN::Meta::JSON";
    plan skip_all => "Test::CPAN::Meta::JSON required for testing META.json" if $@;
}

meta_json_ok();
