#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_compat_accounts.py.
#
# Drives client->compat->accounts->* against the live mock server. Each
# test asserts on both the SDK return value and the recorded request
# journal so neither half is allowed to drift.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

# -------------------- Create --------------------

subtest 'TestCompatAccountsCreate' => sub {
    subtest 'test_returns_account_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->accounts->create(FriendlyName => 'Sub-A');
        # Synthesised response for the Account resource carries a body
        # with friendly_name and date timestamps.
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{friendly_name},
            "missing 'friendly_name' in result keys: " . join(',', sort keys %$result));
    };

    subtest 'test_journal_records_post_to_accounts' => sub {
        my $client = MockTest::client();
        $client->compat->accounts->create(FriendlyName => 'Sub-B');
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        # Accounts.create lives at the top-level Accounts collection - no
        # AccountSid prefix.
        is($j->{path}, '/api/laml/2010-04-01/Accounts', 'path is top-level Accounts');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{FriendlyName}, 'Sub-B', 'FriendlyName forwarded');
        ok($j->{response_status} >= 200 && $j->{response_status} < 400,
            "response_status is 2xx/3xx: got $j->{response_status}");
    };
};

# -------------------- Get --------------------

subtest 'TestCompatAccountsGet' => sub {
    subtest 'test_returns_account_for_sid' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->accounts->get('AC123');
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{friendly_name}, 'retrieve synthesises Account body');
    };

    subtest 'test_journal_records_get_with_sid' => sub {
        my $client = MockTest::client();
        $client->compat->accounts->get('AC_SAMPLE_SID');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path}, '/api/laml/2010-04-01/Accounts/AC_SAMPLE_SID',
            'path includes sid');
        # GET should not carry a request body.
        ok(!defined $j->{body} || $j->{body} eq ''
              || (ref $j->{body} eq 'HASH' && !%{ $j->{body} }),
            'no body on GET');
        isnt($j->{matched_route}, undef, 'matched_route set');
    };
};

# -------------------- Update --------------------

subtest 'TestCompatAccountsUpdate' => sub {
    subtest 'test_returns_updated_account' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->accounts->update(
            'AC123', FriendlyName => 'Renamed',
        );
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{friendly_name}, 'update returns Account body');
    };

    subtest 'test_journal_records_post_to_account_path' => sub {
        my $client = MockTest::client();
        $client->compat->accounts->update('AC_X', FriendlyName => 'NewName');
        my $j = MockTest::journal_last();
        # Twilio-compat update is POST (not PATCH/PUT).
        is($j->{method}, 'POST', 'compat update uses POST');
        is($j->{path}, '/api/laml/2010-04-01/Accounts/AC_X', 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{FriendlyName}, 'NewName', 'FriendlyName forwarded');
    };
};

done_testing();
