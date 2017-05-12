#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

eval 'use Perl::Tidy';
plan skip_all => 'Perl::Tidy required' if $@;

eval "use Test::Code::TidyAll";
plan skip_all => "Test::Code::TidyAll required for testing tidyness"
    if $@;

tidyall_ok();
