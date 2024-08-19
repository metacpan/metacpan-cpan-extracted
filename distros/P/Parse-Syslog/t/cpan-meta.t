use Test::More;
eval "use Test::CPAN::Meta::YAML";
plan skip_all => "Test::CPAN::Meta::YAML required for testing META.yml" if $@;
meta_yaml_ok();
