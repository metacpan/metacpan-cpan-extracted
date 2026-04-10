#!/usr/bin/perl

# Unit tests for Net::Nostr::Report
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Report;
use Net::Nostr::Event;

my $my_pubkey   = 'aa' x 32;
my $spammer_pk  = 'bb' x 32;
my $author_pk   = 'cc' x 32;
my $note_id     = 'dd' x 32;
my $hash        = 'ee' x 32;
my $target_pk   = 'ff' x 32;
my $reporter_pk = 'aa' x 32;
my $containing_event_id = 'dd' x 32;

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: report profile for spam' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $spammer_pk,
        report_type => 'spam',
    );
    is($event->kind, 1984, 'kind 1984');
};

subtest 'SYNOPSIS: report note as illegal' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $author_pk,
        event_id    => $note_id,
        report_type => 'illegal',
        content     => 'Violates local law',
    );
    is($event->kind, 1984, 'kind');
    is($event->content, 'Violates local law', 'content');
};

subtest 'SYNOPSIS: report blob as malware' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $author_pk,
        report_type => 'malware',
        blob_hash   => $hash,
        event_id    => $containing_event_id,
        server      => 'https://example.com/file.ext',
    );
    my @x = grep { $_->[0] eq 'x' } @{$event->tags};
    is($x[0][1], $hash, 'blob hash');
};

subtest 'SYNOPSIS: parse a report' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $spammer_pk,
        report_type => 'spam',
    );
    my $info = Net::Nostr::Report->from_event($event);
    is($info->reported_pubkey, $spammer_pk, 'reported pubkey');
    is($info->report_type, 'spam', 'report type');
};

subtest 'SYNOPSIS: report_filter' => sub {
    my $filter = Net::Nostr::Report->report_filter(
        reported_pk => $target_pk,
    );
    is($filter->{kinds}, [1984], 'kind');
    is($filter->{'#p'}, [$target_pk], 'reported pk');
};

###############################################################################
# report() POD examples
###############################################################################

subtest 'report: with labels' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $spammer_pk,
        report_type => 'spam',
        labels      => [
            ['L', 'namespace'],
            ['l', 'value', 'namespace'],
        ],
    );
    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is(scalar @L, 1, 'L tag');
};

###############################################################################
# from_event() POD example
###############################################################################

subtest 'from_event: all accessors' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $author_pk,
        report_type => 'malware',
        blob_hash   => $hash,
        event_id    => $note_id,
        server      => 'https://example.com/file.ext',
    );
    my $info = Net::Nostr::Report->from_event($event);
    is($info->reported_pubkey, $author_pk, 'reported_pubkey');
    is($info->report_type, 'malware', 'report_type');
    is($info->event_id, $note_id, 'event_id');
    is($info->blob_hash, $hash, 'blob_hash');
    is($info->server, 'https://example.com/file.ext', 'server');
};

###############################################################################
# validate() POD example
###############################################################################

subtest 'validate: POD example' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $spammer_pk,
        report_type => 'spam',
    );
    ok(Net::Nostr::Report->validate($event), 'valid');
};

###############################################################################
# report_filter() POD example
###############################################################################

subtest 'report_filter: all params' => sub {
    my $filter = Net::Nostr::Report->report_filter(
        reported_pk => $target_pk,
        event_id    => $note_id,
        authors     => [$reporter_pk],
    );
    is($filter->{kinds}, [1984], 'kind');
    is($filter->{'#p'}, [$target_pk], 'reported pk');
    is($filter->{'#e'}, [$note_id], 'event');
    is($filter->{authors}, [$reporter_pk], 'authors');
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $pubkey_hex = 'dd' x 32;
    my $event_id_hex = 'ee' x 32;
    my $report = Net::Nostr::Report->new(
        reported_pubkey => $pubkey_hex,
        report_type     => 'spam',
        event_id        => $event_id_hex,
    );
    is $report->reported_pubkey, $pubkey_hex;
    is $report->report_type, 'spam';
    is $report->event_id, $event_id_hex;
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Report->new(report_type => 'spam', bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

done_testing;
