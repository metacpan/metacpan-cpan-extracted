#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('SignalWire::SWML::Schema');
use_ok('SignalWire::SWML::Document');

# ============================================================
# 1. Schema singleton
# ============================================================
subtest 'schema singleton' => sub {
    my $s1 = SignalWire::SWML::Schema->instance;
    my $s2 = SignalWire::SWML::Schema->instance;
    is($s1, $s2, 'same instance returned');
};

# ============================================================
# 2. Verb count
# ============================================================
subtest 'verb count' => sub {
    my $s = SignalWire::SWML::Schema->instance;
    ok($s->verb_count >= 38, 'at least 38 verbs');
};

# ============================================================
# 3. Known verbs exist
# ============================================================
subtest 'known verbs' => sub {
    my $s = SignalWire::SWML::Schema->instance;
    for my $verb (qw(answer ai hangup connect sleep play record
                     sip_refer send_sms pay tap)) {
        ok($s->has_verb($verb), "has verb: $verb");
    }
};

# ============================================================
# 4. Verb details
# ============================================================
subtest 'verb details' => sub {
    my $s = SignalWire::SWML::Schema->instance;
    my $answer = $s->get_verb('answer');
    ok($answer, 'answer verb details');
    is($answer->{verb_name}, 'answer', 'verb_name');
    is($answer->{schema_name}, 'Answer', 'schema_name');
};

# ============================================================
# 5. Unknown verb
# ============================================================
subtest 'unknown verb' => sub {
    my $s = SignalWire::SWML::Schema->instance;
    ok(!$s->has_verb('nonexistent'), 'unknown verb not found');
    ok(!defined $s->get_verb('nonexistent'), 'get_verb returns undef');
};

# ============================================================
# 6. get_verb_names
# ============================================================
subtest 'get_verb_names' => sub {
    my $s = SignalWire::SWML::Schema->instance;
    my @names = $s->get_verb_names;
    ok(scalar @names >= 38, 'enough verb names');
    ok(grep({ $_ eq 'answer' } @names), 'includes answer');
    ok(grep({ $_ eq 'ai' } @names), 'includes ai');
};

# ============================================================
# 7. Document creation and sections
# ============================================================
subtest 'document sections' => sub {
    my $doc = SignalWire::SWML::Document->new;
    is($doc->version, '1.0.0', 'default version');
    $doc->add_section('main');
    ok($doc->has_section('main'), 'has main');
    ok(!$doc->has_section('other'), 'no other');
};

# ============================================================
# 8. Document verbs
# ============================================================
subtest 'document verbs' => sub {
    my $doc = SignalWire::SWML::Document->new;
    $doc->add_section('main');
    $doc->add_verb('main', 'answer', { max_duration => 3600 });
    $doc->add_verb('main', 'hangup', {});
    my $main = $doc->get_section('main');
    is(scalar @$main, 2, 'two verbs');
    is_deeply($main->[0], { answer => { max_duration => 3600 } }, 'answer verb');
};

# ============================================================
# 9. Document to_hash and to_json
# ============================================================
subtest 'document serialization' => sub {
    my $doc = SignalWire::SWML::Document->new;
    $doc->add_section('main');
    $doc->add_verb('main', 'answer', {});

    my $hash = $doc->to_hash;
    is($hash->{version}, '1.0.0', 'hash has version');
    ok(exists $hash->{sections}{main}, 'hash has main');

    my $json = $doc->to_json;
    ok(length($json) > 0, 'JSON not empty');
    my $parsed = JSON::decode_json($json);
    is($parsed->{version}, '1.0.0', 'JSON roundtrip');
};

# ============================================================
# 10. Document clear_section
# ============================================================
subtest 'clear_section' => sub {
    my $doc = SignalWire::SWML::Document->new;
    $doc->add_section('main');
    $doc->add_verb('main', 'answer', {});
    $doc->clear_section('main');
    is(scalar @{$doc->get_section('main')}, 0, 'section cleared');
};

# ============================================================
# 11. Document add_raw_verb
# ============================================================
subtest 'add_raw_verb' => sub {
    my $doc = SignalWire::SWML::Document->new;
    $doc->add_section('main');
    $doc->add_raw_verb('main', { custom_verb => { key => 'value' } });
    is_deeply($doc->get_section('main')->[0], { custom_verb => { key => 'value' } }, 'raw verb added');
};

done_testing;
