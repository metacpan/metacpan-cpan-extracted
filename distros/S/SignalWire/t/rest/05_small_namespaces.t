#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_small_namespaces_mock.py.
#
# Coverage for the smaller namespaces - addresses, recordings, short_codes,
# imported_numbers, mfa, sip_profile, number_groups, project tokens,
# datasphere documents, queues - against the live mock server.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

# -------------------- Addresses --------------------

subtest 'TestAddresses' => sub {
    subtest 'list' => sub {
        my $client = MockTest::client();
        my $body = $client->addresses->list(page_size => 10);
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{data}, 'list response has data key');
        is(ref $body->{data}, 'ARRAY', 'data is arrayref');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},   '/api/relay/rest/addresses', 'path matches');
        isnt($j->{matched_route}, undef, 'matched_route set');
        is_deeply($j->{query_params}{page_size}, ['10'], 'page_size on query');
    };

    subtest 'create' => sub {
        my $client = MockTest::client();
        my $body = $client->addresses->create(
            address_type => 'commercial',
            first_name   => 'Ada',
            last_name    => 'Lovelace',
            country      => 'US',
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'address resource has id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},   '/api/relay/rest/addresses', 'path matches');
        my $sent = $j->{body} || {};
        is($sent->{address_type}, 'commercial', 'address_type forwarded');
        is($sent->{first_name},   'Ada',         'first_name forwarded');
        is($sent->{country},      'US',          'country forwarded');
    };

    subtest 'get' => sub {
        my $client = MockTest::client();
        my $body = $client->addresses->get('addr-123');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'address resource has id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},   '/api/relay/rest/addresses/addr-123', 'path includes id');
        isnt($j->{matched_route}, undef, 'matched_route set');
    };

    subtest 'delete' => sub {
        my $client = MockTest::client();
        my $body = $client->addresses->delete('addr-123');
        is(ref $body, 'HASH', 'delete returns a hashref');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path},   '/api/relay/rest/addresses/addr-123', 'path matches');
        ok($j->{response_status} == 200
              || $j->{response_status} == 202
              || $j->{response_status} == 204,
            "response_status in (200,202,204): got $j->{response_status}");
    };
};

# -------------------- Recordings --------------------

subtest 'TestRecordings' => sub {
    subtest 'list' => sub {
        my $client = MockTest::client();
        my $body = $client->recordings->list(page_size => 5);
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{data}, 'list has data');
        is(ref $body->{data}, 'ARRAY', 'data is arrayref');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},   '/api/relay/rest/recordings', 'path matches');
        is_deeply($j->{query_params}{page_size}, ['5'], 'page_size on query');
    };

    subtest 'get' => sub {
        my $client = MockTest::client();
        my $body = $client->recordings->get('rec-123');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'recording has id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},   '/api/relay/rest/recordings/rec-123', 'path includes id');
    };

    subtest 'delete' => sub {
        my $client = MockTest::client();
        my $body = $client->recordings->delete('rec-123');
        is(ref $body, 'HASH', 'delete returns a hashref');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path},   '/api/relay/rest/recordings/rec-123', 'path matches');
        ok($j->{response_status} == 200
              || $j->{response_status} == 202
              || $j->{response_status} == 204,
            "response_status in (200,202,204): got $j->{response_status}");
    };
};

# -------------------- Short Codes --------------------

subtest 'TestShortCodes' => sub {
    subtest 'list' => sub {
        my $client = MockTest::client();
        my $body = $client->short_codes->list(page_size => 20);
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{data}, 'list has data');
        is(ref $body->{data}, 'ARRAY', 'data is arrayref');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},   '/api/relay/rest/short_codes', 'path matches');
    };

    subtest 'get' => sub {
        my $client = MockTest::client();
        my $body = $client->short_codes->get('sc-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'short_code has id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},   '/api/relay/rest/short_codes/sc-1', 'path includes id');
    };

    subtest 'update' => sub {
        my $client = MockTest::client();
        my $body = $client->short_codes->update('sc-1', name => 'Marketing SMS');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'short_code has id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'PUT', 'short_codes update uses PUT');
        is($j->{path},   '/api/relay/rest/short_codes/sc-1', 'path matches');
        my $sent = $j->{body} || {};
        is($sent->{name}, 'Marketing SMS', 'name forwarded');
    };
};

# -------------------- Imported Numbers --------------------

subtest 'TestImportedNumbers' => sub {
    subtest 'create' => sub {
        my $client = MockTest::client();
        my $body = $client->imported_numbers->create(
            number       => '+15551234567',
            sip_username => 'alice',
            sip_password => 'secret',
            sip_proxy    => 'sip.example.com',
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'imported number has id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},   '/api/relay/rest/imported_phone_numbers', 'path matches');
        my $sent = $j->{body} || {};
        is($sent->{number},       '+15551234567',     'number forwarded');
        is($sent->{sip_username}, 'alice',            'sip_username forwarded');
        is($sent->{sip_proxy},    'sip.example.com', 'sip_proxy forwarded');
    };
};

# -------------------- MFA - voice channel --------------------

subtest 'TestMfa' => sub {
    subtest 'call' => sub {
        my $client = MockTest::client();
        # Note Python's `from_=` becomes plain `from_` here; from is reserved
        # in some languages but Perl is fine with from_.
        my $body = $client->mfa->call(
            to       => '+15551234567',
            from_    => '+15559876543',
            message  => 'Your code is {code}',
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'mfa response has id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},   '/api/relay/rest/mfa/call', 'path matches');
        my $sent = $j->{body} || {};
        is($sent->{to},      '+15551234567',          'to forwarded');
        is($sent->{from_},   '+15559876543',          'from_ forwarded');
        is($sent->{message}, 'Your code is {code}',    'message forwarded');
    };
};

# -------------------- SIP Profile --------------------

subtest 'TestSipProfile' => sub {
    subtest 'update' => sub {
        my $client = MockTest::client();
        my $body = $client->sip_profile->update(
            domain         => 'myco.sip.signalwire.com',
            default_codecs => ['PCMU', 'PCMA'],
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{domain} || exists $body->{default_codecs},
            'sip_profile resource has domain or default_codecs');
        my $j = MockTest::journal_last();
        is($j->{method}, 'PUT', 'sip_profile update uses PUT');
        is($j->{path},   '/api/relay/rest/sip_profile', 'path matches');
        my $sent = $j->{body} || {};
        is($sent->{domain},          'myco.sip.signalwire.com', 'domain forwarded');
        is_deeply($sent->{default_codecs}, ['PCMU', 'PCMA'], 'default_codecs forwarded');
    };
};

# -------------------- Number Groups - membership ops --------------------

subtest 'TestNumberGroups' => sub {
    subtest 'list_memberships' => sub {
        my $client = MockTest::client();
        my $body = $client->number_groups->list_memberships('ng-1', page_size => 10);
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{data}, 'list has data');
        is(ref $body->{data}, 'ARRAY', 'data is arrayref');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},
           '/api/relay/rest/number_groups/ng-1/number_group_memberships',
           'path matches');
        is_deeply($j->{query_params}{page_size}, ['10'], 'page_size on query');
    };

    subtest 'delete_membership' => sub {
        my $client = MockTest::client();
        my $body = $client->number_groups->delete_membership('mem-1');
        is(ref $body, 'HASH', 'delete returns a hashref');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path},   '/api/relay/rest/number_group_memberships/mem-1', 'path matches');
        ok($j->{response_status} == 200
              || $j->{response_status} == 202
              || $j->{response_status} == 204,
            "response_status in (200,202,204): got $j->{response_status}");
    };
};

# -------------------- Project tokens --------------------

subtest 'TestProjectTokens' => sub {
    subtest 'update' => sub {
        my $client = MockTest::client();
        my $body = $client->project_ns->tokens->update('tok-1', name => 'renamed-token');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'project token has id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'PATCH', 'PATCH recorded');
        is($j->{path},   '/api/project/tokens/tok-1', 'path matches');
        my $sent = $j->{body} || {};
        is($sent->{name}, 'renamed-token', 'name forwarded');
    };

    subtest 'delete' => sub {
        my $client = MockTest::client();
        my $body = $client->project_ns->tokens->delete('tok-1');
        is(ref $body, 'HASH', 'delete returns a hashref');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path},   '/api/project/tokens/tok-1', 'path matches');
        ok($j->{response_status} == 200
              || $j->{response_status} == 202
              || $j->{response_status} == 204,
            "response_status in (200,202,204): got $j->{response_status}");
    };
};

# -------------------- Datasphere documents --------------------

subtest 'TestDatasphere' => sub {
    subtest 'get_chunk' => sub {
        my $client = MockTest::client();
        my $body = $client->datasphere->documents->get_chunk('doc-1', 'chunk-99');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'chunk has id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},
           '/api/datasphere/documents/doc-1/chunks/chunk-99',
           'path matches');
    };
};

# -------------------- Queues --------------------

subtest 'TestQueues' => sub {
    subtest 'get_member' => sub {
        my $client = MockTest::client();
        my $body = $client->queues->get_member('q-1', 'mem-7');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{queue_id} || exists $body->{call_id},
            'queue member has queue_id or call_id');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},   '/api/relay/rest/queues/q-1/members/mem-7', 'path matches');
    };
};

done_testing();
