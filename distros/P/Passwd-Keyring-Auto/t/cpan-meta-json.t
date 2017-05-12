use Test::More;

BEGIN {
    plan skip_all => 'these tests are for release candidate testing'
      unless $ENV{RELEASE_TESTING};
}

eval "use Test::CPAN::Meta::JSON";
plan skip_all => "Test::CPAN::Meta::JSON required for testing META.json" if $@;
meta_json_ok();