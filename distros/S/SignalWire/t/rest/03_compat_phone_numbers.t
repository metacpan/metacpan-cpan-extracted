#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_compat_phone_numbers.py.
#
# Covers:
#   list, get, update, delete (basic CRUD over IncomingPhoneNumbers)
#   purchase, import_number (phone-number provisioning)
#   list_available_countries, search_toll_free

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

subtest 'TestCompatPhoneNumbersList' => sub {
    subtest 'returns_paginated_list' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->phone_numbers->list();
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{incoming_phone_numbers},
            "list has 'incoming_phone_numbers' (got keys: " . join(',', sort keys %$result) . ")");
        is(ref $result->{incoming_phone_numbers}, 'ARRAY',
            'incoming_phone_numbers is an arrayref');
    };

    subtest 'journal_records_get_to_incoming_phone_numbers' => sub {
        my $client = MockTest::client();
        $client->compat->phone_numbers->list();
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/IncomingPhoneNumbers',
           'path is /IncomingPhoneNumbers');
    };
};

subtest 'TestCompatPhoneNumbersGet' => sub {
    subtest 'returns_phone_number_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->phone_numbers->get('PN_TEST');
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{phone_number} || exists $result->{sid},
            'has phone_number or sid');
    };

    subtest 'journal_records_get_with_sid' => sub {
        my $client = MockTest::client();
        $client->compat->phone_numbers->get('PN_GET');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/IncomingPhoneNumbers/PN_GET',
           'GET path includes sid');
    };
};

subtest 'TestCompatPhoneNumbersUpdate' => sub {
    subtest 'returns_phone_number_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->phone_numbers->update(
            'PN_U', FriendlyName => 'updated',
        );
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{phone_number} || exists $result->{sid},
            'has phone_number or sid');
    };

    subtest 'journal_records_post_with_friendly_name' => sub {
        my $client = MockTest::client();
        $client->compat->phone_numbers->update(
            'PN_UU',
            FriendlyName => 'updated',
            VoiceUrl     => 'https://a.b/v',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/IncomingPhoneNumbers/PN_UU',
           'path includes sid');
        is(ref $j->{body}, 'HASH', 'body is a hashref');
        is($j->{body}{FriendlyName}, 'updated',          'FriendlyName forwarded');
        is($j->{body}{VoiceUrl},     'https://a.b/v',     'VoiceUrl forwarded');
    };
};

subtest 'TestCompatPhoneNumbersDelete' => sub {
    subtest 'no_exception_on_delete' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->phone_numbers->delete('PN_D');
        is(ref $result, 'HASH', 'delete returns a hashref');
    };

    subtest 'journal_records_delete_at_phone_number_path' => sub {
        my $client = MockTest::client();
        $client->compat->phone_numbers->delete('PN_DEL');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/IncomingPhoneNumbers/PN_DEL',
           'DELETE path includes sid');
    };
};

subtest 'TestCompatPhoneNumbersPurchase' => sub {
    subtest 'returns_purchased_number' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->phone_numbers->purchase(
            PhoneNumber => '+15555550100',
        );
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{phone_number} || exists $result->{sid},
            'has phone_number or sid');
    };

    subtest 'journal_records_post_with_phone_number' => sub {
        my $client = MockTest::client();
        $client->compat->phone_numbers->purchase(
            PhoneNumber  => '+15555550100',
            FriendlyName => 'Main',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/IncomingPhoneNumbers',
           'POST goes to /IncomingPhoneNumbers');
        is(ref $j->{body}, 'HASH', 'body is a hashref');
        is($j->{body}{PhoneNumber},  '+15555550100', 'PhoneNumber forwarded');
        is($j->{body}{FriendlyName}, 'Main',          'FriendlyName forwarded');
    };
};

subtest 'TestCompatPhoneNumbersImportNumber' => sub {
    subtest 'returns_imported_number' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->phone_numbers->import_number(
            PhoneNumber => '+15555550111',
        );
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{phone_number} || exists $result->{sid},
            'imported number has phone_number or sid');
    };

    subtest 'journal_records_post_to_imported_phone_numbers' => sub {
        my $client = MockTest::client();
        $client->compat->phone_numbers->import_number(
            PhoneNumber => '+15555550111',
            VoiceUrl    => 'https://a.b/v',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/ImportedPhoneNumbers',
           'POST goes to /ImportedPhoneNumbers (not /IncomingPhoneNumbers)');
        is(ref $j->{body}, 'HASH', 'body is a hashref');
        is($j->{body}{PhoneNumber}, '+15555550111', 'PhoneNumber forwarded');
    };
};

subtest 'TestCompatPhoneNumbersListAvailableCountries' => sub {
    subtest 'returns_countries_collection' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->phone_numbers->list_available_countries();
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{countries},
            "has 'countries' key (got keys: " . join(',', sort keys %$result) . ")");
        is(ref $result->{countries}, 'ARRAY', 'countries is an arrayref');
    };

    subtest 'journal_records_get_to_available_phone_numbers' => sub {
        my $client = MockTest::client();
        $client->compat->phone_numbers->list_available_countries();
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/AvailablePhoneNumbers',
           'GET goes to /AvailablePhoneNumbers');
    };
};

subtest 'TestCompatPhoneNumbersSearchTollFree' => sub {
    subtest 'returns_available_numbers' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->phone_numbers->search_toll_free(
            'US', AreaCode => '800',
        );
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{available_phone_numbers},
            "has 'available_phone_numbers' (got keys: " . join(',', sort keys %$result) . ")");
        is(ref $result->{available_phone_numbers}, 'ARRAY',
            'available_phone_numbers is an arrayref');
    };

    subtest 'journal_records_get_with_country_in_path' => sub {
        my $client = MockTest::client();
        $client->compat->phone_numbers->search_toll_free('US', AreaCode => '888');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/AvailablePhoneNumbers/US/TollFree',
           'GET path includes country');
        ok(exists $j->{query_params}{AreaCode},
            'AreaCode appears on the query string');
        is_deeply($j->{query_params}{AreaCode}, ['888'],
            'AreaCode value forwarded as query, not body');
    };
};

done_testing();
