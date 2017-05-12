# check that a TBX::Min object can be created from a TBX-Min XML file.

use strict;
use warnings;
use Test::More 0.88;
plan tests => 47;
use Test::NoWarnings;
use TBX::Min;
use FindBin qw($Bin);
use Path::Tiny;
use Test::Exception;

my $basic_path = path($Bin, 'corpus', 'min.tbx');
my $basic_txt = $basic_path->slurp;

note('reading XML file');
test_read("$basic_path");

note('reading XML string');
test_read(\$basic_txt);

test_empty_tbx();

test_errors();

sub test_read {
    my ($input) = @_;
    my $min = TBX::Min->new_from_xml($input);

    isa_ok($min, 'TBX::Min');
    test_header($min);
    test_body($min);
}

sub test_header {
    my ($min) = @_;
    is($min->id, 'TBX sample', 'correct id');
    is($min->creator, 'Klaus-Dirk Schmidt', 'correct creator');
    is($min->license, 'CC BY license can be freely copied and modified',
        'correct license');
    is($min->directionality, 'bidirectional', 'correct directionality');
    is($min->source_lang, 'de', 'correct source language');
    is($min->target_lang, 'en', 'correct target language');
}

sub test_body {
    my ($min) = @_;
    my $entries = $min->entries;
    is(scalar @$entries, 3, 'found three entries');

    my $concept = $entries->[0];
    isa_ok($concept, 'TBX::Min::TermEntry');
    is($concept->id, 'C002', 'correct concept ID');
    is($concept->subject_field, 'biology',
        'correct concept subject field');
    my $languages = $concept->lang_groups;
    is(scalar @$languages, 2, 'found two languages');

    my $language = $languages->[1];
    isa_ok($language, 'TBX::Min::LangSet');
    is($language->code, 'en', 'language is English');
    my $terms = $language->term_groups;
    is(scalar @$terms, 2, 'found two terms');

    my $term = $terms->[1];
    isa_ok($term, 'TBX::Min::TIG');
    is($term->term, 'hound', 'correct term text');
    is($term->part_of_speech, 'noun', 'correct part of speech');
    is($term->status, 'obsolete', 'correct status');
    is($term->customer, 'SAP', 'correct customer');
    my $note = $term->note_groups->[0]->notes->[0];
    is($note->noteKey, 'usage', 'correct note key');
    is($note->noteValue, 'however bloodhound is used rather than blooddog',
        'correct note value');
}

# simple check that "entries" sub returns empty array, not undef
sub test_empty_tbx {
    my $empty_tbx = '<TBX dialect="TBX-Min"/>';
    my $min = TBX::Min->new_from_xml(\$empty_tbx);
    is_deeply($min->entries, [], 'entries returns [] by default');
}

sub test_errors {
    subtest 'die on bad dialect' => sub {
        plan tests => 2;
        throws_ok(
            sub {
                TBX::Min->new_from_xml(\'<TBX dialect="whatevs"/>')
            },
            qr{input TBX is whatevs \(should be 'TBX-Min'\)}i,
            'incorrect dialect' );
        throws_ok(
            sub {
                TBX::Min->new_from_xml(\'<TBX/>')
            },
            qr{input TBX is unknown \(should be 'TBX-Min'\)}i,
            'incorrect dialect' );
    };
}
