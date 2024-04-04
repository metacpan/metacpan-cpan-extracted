package Stancer::Core::Types::ApiKeys::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Core::Types::ApiKeys::Stub;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub api_key : Tests(14) {
    ok(Stancer::Core::Types::ApiKeys::Stub->new(an_api_key => 'pprod_' . random_string(24)), 'Public live key');
    ok(Stancer::Core::Types::ApiKeys::Stub->new(an_api_key => 'ptest_' . random_string(24)), 'Public test key');
    ok(Stancer::Core::Types::ApiKeys::Stub->new(an_api_key => 'sprod_' . random_string(24)), 'Secret live key');
    ok(Stancer::Core::Types::ApiKeys::Stub->new(an_api_key => 'stest_' . random_string(24)), 'Secret test key');

    my $regex = qr/is not a valid API key/sm;

    throws_ok { Stancer::Core::Types::ApiKeys::Stub->new(an_api_key => undef) } $regex, 'undef is not valid';

    my $no_prefix = random_string(30);

    throws_ok { Stancer::Core::Types::ApiKeys::Stub->new(an_api_key => $no_prefix) } $regex, $no_prefix . ' is not valid';

    for my $prefix (qw(pprod ptest sprod stest)) {
        my $too_short = $prefix . '_' . random_string(23);
        my $too_long = $prefix . '_' . random_string(25);

        throws_ok {
            Stancer::Core::Types::ApiKeys::Stub->new(an_api_key => $too_short)
        } $regex, $too_short . ' is too short';

        throws_ok {
            Stancer::Core::Types::ApiKeys::Stub->new(an_api_key => $too_long)
        } $regex, $too_long . ' is too long';
    }
}

sub public_live_api_key : Tests(7) {
    ok(Stancer::Core::Types::ApiKeys::Stub->new(a_public_live_api_key => 'pprod_' . random_string(24)), 'Public live key');

    my $regex = qr/is not a valid public API key for live mode/sm;

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_live_api_key => 'ptest_' . random_string(24))
    } $regex, 'Public test key is not valid';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_live_api_key => 'sprod_' . random_string(24))
    } $regex, 'Secret live key is not valid';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_live_api_key => 'stest_' . random_string(24))
    } $regex, 'Secret test key is not valid';

    throws_ok { Stancer::Core::Types::ApiKeys::Stub->new(a_public_live_api_key => undef) } $regex, 'undef is not valid';

    my $too_short = 'pprod_' . random_string(23);
    my $too_long = 'pprod_' . random_string(25);

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_live_api_key => $too_short)
    } $regex, $too_short . ' is too short';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_live_api_key => $too_long)
    } $regex, $too_long . ' is too long';
}

sub public_test_api_key : Tests(7) {
    ok(Stancer::Core::Types::ApiKeys::Stub->new(a_public_test_api_key => 'ptest_' . random_string(24)), 'Public test key');

    my $regex = qr/is not a valid public API key for test mode/sm;

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_test_api_key => 'pprod_' . random_string(24))
    } $regex, 'Public live key is not valid';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_test_api_key => 'sprod_' . random_string(24))
    } $regex, 'Secret live key is not valid';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_test_api_key => 'stest_' . random_string(24))
    } $regex, 'Secret test key is not valid';

    throws_ok { Stancer::Core::Types::ApiKeys::Stub->new(a_public_test_api_key => undef) } $regex, 'undef is not valid';

    my $too_short = 'ptest_' . random_string(23);
    my $too_long = 'ptest_' . random_string(25);

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_test_api_key => $too_short)
    } $regex, $too_short . ' is too short';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_public_test_api_key => $too_long)
    } $regex, $too_long . ' is too long';
}

sub secret_live_api_key : Tests(7) {
    ok(Stancer::Core::Types::ApiKeys::Stub->new(a_secret_live_api_key => 'sprod_' . random_string(24)), 'Secret live key');

    my $regex = qr/is not a valid secret API key for live mode/sm;

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_live_api_key => 'pprod_' . random_string(24))
    } $regex, 'Public live key is not valid';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_live_api_key => 'ptest_' . random_string(24))
    } $regex, 'Public test key is not valid';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_live_api_key => 'stest_' . random_string(24))
    } $regex, 'Secret test key is not valid';

    throws_ok { Stancer::Core::Types::ApiKeys::Stub->new(a_secret_live_api_key => undef) } $regex, 'undef is not valid';

    my $too_short = 'sprod_' . random_string(23);
    my $too_long = 'sprod_' . random_string(25);

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_live_api_key => $too_short)
    } $regex, $too_short . ' is too short';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_live_api_key => $too_long)
    } $regex, $too_long . ' is too long';
}

sub secret_test_api_key : Tests(7) {
    ok(Stancer::Core::Types::ApiKeys::Stub->new(a_secret_test_api_key => 'stest_' . random_string(24)), 'Secret test key');

    my $regex = qr/is not a valid secret API key for test mode/sm;

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_test_api_key => 'pprod_' . random_string(24))
    } $regex, 'Public live key is not valid';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_test_api_key => 'ptest_' . random_string(24))
    } $regex, 'Public test key is not valid';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_test_api_key => 'sprod_' . random_string(24))
    } $regex, 'Secret live key is not valid';

    throws_ok { Stancer::Core::Types::ApiKeys::Stub->new(a_secret_test_api_key => undef) } $regex, 'undef is not valid';

    my $too_short = 'stest_' . random_string(23);
    my $too_long = 'stest_' . random_string(25);

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_test_api_key => $too_short)
    } $regex, $too_short . ' is too short';

    throws_ok {
        Stancer::Core::Types::ApiKeys::Stub->new(a_secret_test_api_key => $too_long)
    } $regex, $too_long . ' is too long';
}

1;
