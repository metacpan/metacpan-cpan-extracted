use Test::More;

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import( tests => ['-use_strict'] );
};
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
