#!/usr/bin/env perl -w

use strict;
use Test::More;
use lib::abs;

chdir lib::abs::path '..' or plan skip_all => "Can't chdir to dist: $!";

$ENV{TEST_AUTHOR} or plan skip_all => '$ENV{TEST_AUTHOR} not set';
eval "use Test::YAML::Meta;1"
	or plan skip_all => "Test::YAML::Meta required for testing META.yml";

meta_yaml_ok();
