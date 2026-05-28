#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_compat_tokens.py.
#
# Covers CompatTokens.create / .update / .delete. Note: CompatTokens
# extends Base (not CrudResource), so update uses PATCH not POST.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

my $BASE = '/api/laml/2010-04-01/Accounts/test_proj/tokens';

subtest 'TestCompatTokensCreate' => sub {
    subtest 'test_returns_token_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->tokens->create(Ttl => 3600);
        is(ref $result, 'HASH', 'expected hashref');
        # Token resources carry id + token + permissions.
        ok(exists $result->{token} || exists $result->{id},
            'has token or id');
    };

    subtest 'test_journal_records_post_with_ttl' => sub {
        my $client = MockTest::client();
        $client->compat->tokens->create(Ttl => 3600, Name => 'api-key');
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, $BASE, 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{Ttl}, 3600, 'Ttl forwarded');
        is($j->{body}{Name}, 'api-key', 'Name forwarded');
    };
};

subtest 'TestCompatTokensUpdate' => sub {
    subtest 'test_returns_token_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->tokens->update('TK_U', Ttl => 7200);
        is(ref $result, 'HASH', 'expected hashref');
        ok(exists $result->{token} || exists $result->{id},
            'has token or id');
    };

    subtest 'test_journal_records_patch_with_ttl' => sub {
        my $client = MockTest::client();
        $client->compat->tokens->update('TK_UU', Ttl => 7200);
        my $j = MockTest::journal_last();
        # CompatTokens.update uses PATCH (Base.update -> http.patch).
        is($j->{method}, 'PATCH', 'PATCH recorded (not POST)');
        is($j->{path}, "$BASE/TK_UU", 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{Ttl}, 7200, 'Ttl forwarded');
    };
};

subtest 'TestCompatTokensDelete' => sub {
    subtest 'test_no_exception_on_delete' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->tokens->delete('TK_D');
        is(ref $result, 'HASH', 'delete returns hashref');
    };

    subtest 'test_journal_records_delete' => sub {
        my $client = MockTest::client();
        $client->compat->tokens->delete('TK_DEL');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path}, "$BASE/TK_DEL", 'path matches');
    };
};

done_testing();
