#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_compat_misc.py.
#
# Covers compat resources with single-method gaps:
#   - CompatApplications.update
#   - CompatLamlBins.update

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

my $BASE = '/api/laml/2010-04-01/Accounts/test_proj';

# ---- Applications --------------------------------------------------------

subtest 'TestCompatApplicationsUpdate' => sub {
    subtest 'test_returns_application_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->applications->update(
            'AP_U', FriendlyName => 'updated',
        );
        is(ref $result, 'HASH', 'expected hashref');
        # Application resources carry friendly_name + sid + voice_url.
        ok(exists $result->{friendly_name} || exists $result->{sid},
            'has friendly_name or sid');
    };

    subtest 'test_journal_records_post_with_friendly_name' => sub {
        my $client = MockTest::client();
        $client->compat->applications->update(
            'AP_UU',
            FriendlyName => 'renamed',
            VoiceUrl     => 'https://a.b/v',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, "$BASE/Applications/AP_UU", 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{FriendlyName}, 'renamed', 'FriendlyName forwarded');
        is($j->{body}{VoiceUrl}, 'https://a.b/v', 'VoiceUrl forwarded');
    };
};

# ---- LamlBins ------------------------------------------------------------

subtest 'TestCompatLamlBinsUpdate' => sub {
    subtest 'test_returns_laml_bin_resource' => sub {
        my $client = MockTest::client();
        my $result = $client->compat->laml_bins->update(
            'LB_U', FriendlyName => 'updated',
        );
        is(ref $result, 'HASH', 'expected hashref');
        # LAML bin resources carry friendly_name + sid + contents.
        ok(exists $result->{friendly_name}
              || exists $result->{sid}
              || exists $result->{contents},
            'has friendly_name, sid, or contents');
    };

    subtest 'test_journal_records_post_with_friendly_name' => sub {
        my $client = MockTest::client();
        $client->compat->laml_bins->update(
            'LB_UU',
            FriendlyName => 'renamed',
            Contents     => '<Response/>',
        );
        my $j = MockTest::journal_last();
        is($j->{method}, 'POST', 'POST recorded');
        is($j->{path}, "$BASE/LamlBins/LB_UU", 'path matches');
        is(ref $j->{body}, 'HASH', 'body is hashref');
        is($j->{body}{FriendlyName}, 'renamed', 'FriendlyName forwarded');
        is($j->{body}{Contents}, '<Response/>', 'Contents forwarded');
    };
};

done_testing();
