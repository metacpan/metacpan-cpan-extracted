use Test::More;

plan skip_all => "author test" unless($ENV{RELEASE_TESTING});

eval {
  require Test::Kwalitee;
  Test::Kwalitee->import(
    tests => [
        '-has_test_pod_coverage',
        '-use_strict', # moose imports strict
    ]
  )
};

diag($@);
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

