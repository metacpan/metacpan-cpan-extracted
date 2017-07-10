use Test::More;
use Module::Build;
use Try::Tiny;
eval 'use Test::CPAN::Changes';
plan skip_all => 'Test::CPAN::Changes required for this test' if $@;
try {
  plan skip_all => "Not calling from build process" unless Module::Build->current;
  changes_ok();
} catch {
  plan skip_all => "Author tests"
};
