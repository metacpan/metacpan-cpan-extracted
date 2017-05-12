#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;

eval 'use Test::NoTabs';
plan skip_all => 'Test::NoTabs required' if $@;

all_perl_files_ok();
