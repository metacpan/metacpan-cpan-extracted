#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    eval "use Test::CPAN::Meta";
    plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;
}

meta_yaml_ok();
