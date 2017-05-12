# This test is only run if RELEASE_TESTING is set in the environment and
# Test::Kwalitee is installed.  Unless both are true, it skips everything and is harmless.

BEGIN {
    unless ($ENV{RELEASE_TESTING})
    {
        use Test::More;
        plan(skip_all => 'These tests are for release candidate testing');
    }
}

BEGIN {
    eval {
        require Test::Kwalitee;
    };
    if ($@) {
        plan(skip_all => 'Test::Kwalitee not installed');
    }
    else {
        Test::Kwalitee->import;
    }
}
