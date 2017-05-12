use Test::More;

BEGIN {
    plan skip_all => 'these tests are for release candidate testing'
      unless $ENV{RELEASE_TESTING};
}

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;
meta_yaml_ok();