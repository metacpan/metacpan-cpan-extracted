use Test::More;

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        plan(skip_all => 'these tests are for release candidate testing');
    }
}

eval { require Test::Kwalitee; Test::Kwalitee->import };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
