use strict;
use warnings;

use Test::More;

my @metatesters = (
	'Test::CPAN::Meta::YAML 0.13',
	'Test::CPAN::Meta 0.14',
);
eval "use $_" and last for @metatesters;
plan skip_all => "Test::CPAN::Meta(::YAML) required to test META.yml" if $@;

meta_yaml_ok();

