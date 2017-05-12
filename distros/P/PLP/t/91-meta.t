use strict;
use warnings;

use Test::More;
eval 'use Test::YAML::Meta';
plan skip_all => "Test::YAML::Meta required to test META.yml" if $@;
plan skip_all => "Test::YAML::Meta v0.10 required to test META.yml correctly"
	if $Test::YAML::Meta::VERSION < 0.10;

meta_yaml_ok();

