#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_compat_messages_faxes.py.
#
# Covers Messages: update, get_media, delete_media
#        Faxes:    update, list_media, get_media, delete_media

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

# -------------------- Messages --------------------

subtest 'TestCompatMessagesUpdate' => sub {
    subtest 'returns_message_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->messages->update(
            'MM_TEST', Body => 'updated body',
        );
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{body} || exists $result->{sid},
            'message resource has body or sid');
    };

    subtest 'journal_records_post_to_message' => sub {
        my $client = MockTest::client();
        $client->compat->messages->update('MM_U1', Body => 'x', Status => 'canceled');
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Messages/MM_U1',
           'path is /Messages/{sid}');
        is(ref $j->{body}, 'HASH', 'body is a hashref');
        is($j->{body}{Body},   'x',        'Body forwarded');
        is($j->{body}{Status}, 'canceled', 'Status forwarded');
    };
};

subtest 'TestCompatMessagesGetMedia' => sub {
    subtest 'returns_media_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->messages->get_media('MM_GM', 'ME_GM');
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{content_type} || exists $result->{sid},
            'media resource has content_type or sid');
    };

    subtest 'journal_records_get_to_media_path' => sub {
        my $client = MockTest::client();
        $client->compat->messages->get_media('MM_X', 'ME_X');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Messages/MM_X/Media/ME_X',
           'path is /Messages/{sid}/Media/{media_sid}');
    };
};

subtest 'TestCompatMessagesDeleteMedia' => sub {
    subtest 'no_exception_on_delete' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->messages->delete_media('MM_DM', 'ME_DM');
        is(ref $result, 'HASH', 'delete returns a hashref (possibly empty)');
    };

    subtest 'journal_records_delete' => sub {
        my $client = MockTest::client();
        $client->compat->messages->delete_media('MM_D', 'ME_D');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Messages/MM_D/Media/ME_D',
           'DELETE path is /Messages/{sid}/Media/{media_sid}');
    };
};

# -------------------- Faxes --------------------

subtest 'TestCompatFaxesUpdate' => sub {
    subtest 'returns_fax_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->faxes->update('FX_U', Status => 'canceled');
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{status} || exists $result->{direction},
            'fax resource has status or direction');
    };

    subtest 'journal_records_post_with_status' => sub {
        my $client = MockTest::client();
        $client->compat->faxes->update('FX_U2', Status => 'canceled');
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Faxes/FX_U2',
           'path is /Faxes/{sid}');
        is(ref $j->{body}, 'HASH', 'body is a hashref');
        is($j->{body}{Status}, 'canceled', 'Status forwarded');
    };
};

subtest 'TestCompatFaxesListMedia' => sub {
    subtest 'returns_paginated_list' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->faxes->list_media('FX_LM');
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{media} || exists $result->{fax_media},
            "fax media list has 'media' or 'fax_media' (got keys: " . join(',', sort keys %$result) . ")");
    };

    subtest 'journal_records_get_to_fax_media' => sub {
        my $client = MockTest::client();
        $client->compat->faxes->list_media('FX_LM_X');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Faxes/FX_LM_X/Media',
           'path is /Faxes/{sid}/Media');
    };
};

subtest 'TestCompatFaxesGetMedia' => sub {
    subtest 'returns_fax_media_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->faxes->get_media('FX_GM', 'ME_GM');
        is(ref $result, 'HASH', 'response is a hashref');
        ok(exists $result->{content_type} || exists $result->{sid},
            'fax media has content_type or sid');
    };

    subtest 'journal_records_get_to_specific_media' => sub {
        my $client = MockTest::client();
        $client->compat->faxes->get_media('FX_G', 'ME_G');
        my $j = MockTest::journal_last();
        is($j->{method}, 'GET', 'GET recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Faxes/FX_G/Media/ME_G',
           'path is /Faxes/{sid}/Media/{media_sid}');
    };
};

subtest 'TestCompatFaxesDeleteMedia' => sub {
    subtest 'no_exception_on_delete' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->faxes->delete_media('FX_DM', 'ME_DM');
        is(ref $result, 'HASH', 'delete returns a hashref');
    };

    subtest 'journal_records_delete' => sub {
        my $client = MockTest::client();
        $client->compat->faxes->delete_media('FX_D', 'ME_D');
        my $j = MockTest::journal_last();
        is($j->{method}, 'DELETE', 'DELETE recorded');
        is($j->{path},
           '/api/laml/2010-04-01/Accounts/test_proj/Faxes/FX_D/Media/ME_D',
           'DELETE path is /Faxes/{sid}/Media/{media_sid}');
    };
};

done_testing();
