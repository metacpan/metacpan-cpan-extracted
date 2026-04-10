#!/usr/bin/perl

# NIP-56 conformance tests: Reporting

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Report;
use Net::Nostr::Event;

my $PUBKEY    = 'aa' x 32;
my $PUBKEY2   = 'bb' x 32;
my $EVID      = 'cc' x 32;
my $BLOB_HASH = 'dd' x 32;

###############################################################################
# report() — create kind 1984 report event
###############################################################################

subtest 'report: profile report with report type' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'spam',
    );
    is($event->kind, 1984, 'kind 1984');
    is($event->pubkey, $PUBKEY, 'pubkey');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 1, 'one p tag');
    is($p[0], ['p', $PUBKEY2, 'spam'], 'p tag with report type');
};

subtest 'report: note report with e and p tags' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        event_id    => $EVID,
        report_type => 'illegal',
    );
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0], ['e', $EVID, 'illegal'], 'e tag with report type');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0], ['p', $PUBKEY2], 'p tag without type for note reports');
};

subtest 'report: content MAY contain additional info' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'illegal',
        event_id    => $EVID,
        content     => "He's insulting the king!",
    );
    is($event->content, "He's insulting the king!", 'content');
};

subtest 'report: default content is empty' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'spam',
    );
    is($event->content, '', 'empty content by default');
};

subtest 'report: requires pubkey' => sub {
    like(dies {
        Net::Nostr::Report->report(
            reported_pk => $PUBKEY2,
            report_type => 'spam',
        );
    }, qr/pubkey/, 'requires pubkey');
};

subtest 'report: requires reported_pk' => sub {
    like(dies {
        Net::Nostr::Report->report(
            pubkey      => $PUBKEY,
            report_type => 'spam',
        );
    }, qr/reported_pk/, 'requires reported_pk');
};

subtest 'report: requires report_type' => sub {
    like(dies {
        Net::Nostr::Report->report(
            pubkey      => $PUBKEY,
            reported_pk => $PUBKEY2,
        );
    }, qr/report_type/, 'requires report_type');
};

###############################################################################
# Report types — all valid types
###############################################################################

subtest 'all report types accepted' => sub {
    for my $type (qw(nudity malware profanity illegal spam impersonation other)) {
        my $event = Net::Nostr::Report->report(
            pubkey      => $PUBKEY,
            reported_pk => $PUBKEY2,
            report_type => $type,
        );
        my @p = grep { $_->[0] eq 'p' } @{$event->tags};
        is($p[0][2], $type, "report type: $type");
    }
};

subtest 'invalid report type rejected' => sub {
    like(dies {
        Net::Nostr::Report->report(
            pubkey      => $PUBKEY,
            reported_pk => $PUBKEY2,
            report_type => 'invalid',
        );
    }, qr/report.type/i, 'invalid type rejected');
};

###############################################################################
# Spec examples — exact JSON from NIP-56
###############################################################################

subtest 'spec example 1: profile nudity report with NIP-32 labels' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'nudity',
        labels      => [
            ['L', 'social.nos.ontology'],
            ['l', 'NS-nud', 'social.nos.ontology'],
        ],
    );
    is($event->kind, 1984, 'kind 1984');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0], ['p', $PUBKEY2, 'nudity'], 'p tag with nudity');

    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is($L[0][1], 'social.nos.ontology', 'L tag');

    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is($l[0], ['l', 'NS-nud', 'social.nos.ontology'], 'l tag');

    is($event->content, '', 'empty content');
};

subtest 'spec example 2: note illegal report with content' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        event_id    => $EVID,
        report_type => 'illegal',
        content     => "He's insulting the king!",
    );
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0], ['e', $EVID, 'illegal'], 'e tag with illegal type');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0], ['p', $PUBKEY2], 'p tag');

    is($event->content, "He's insulting the king!", 'content');
};

subtest 'spec example 3: impersonation report' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'impersonation',
        content     => "Profile is impersonating nostr:npub1victim",
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0], ['p', $PUBKEY2, 'impersonation'], 'p tag with impersonation');
    is($event->content, 'Profile is impersonating nostr:npub1victim', 'content');
};

subtest 'spec example 4: blob malware report with x, e, and server tags' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'malware',
        blob_hash   => $BLOB_HASH,
        event_id    => $EVID,
        server      => 'https://you-may-find-the-blob-here.com/path-to-url.ext',
        content     => 'This file contains malware software in it.',
    );
    my @x = grep { $_->[0] eq 'x' } @{$event->tags};
    is($x[0], ['x', $BLOB_HASH, 'malware'], 'x tag with malware');

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0], ['e', $EVID, 'malware'], 'e tag with malware');

    my @s = grep { $_->[0] eq 'server' } @{$event->tags};
    is($s[0], ['server', 'https://you-may-find-the-blob-here.com/path-to-url.ext'], 'server tag');

    is($event->content, 'This file contains malware software in it.', 'content');
};

###############################################################################
# x tag — blob reporting
###############################################################################

subtest 'blob report: x tag requires event_id' => sub {
    like(dies {
        Net::Nostr::Report->report(
            pubkey      => $PUBKEY,
            reported_pk => $PUBKEY2,
            report_type => 'malware',
            blob_hash   => $BLOB_HASH,
        );
    }, qr/event_id|e tag/i, 'blob report requires event_id');
};

subtest 'blob report: server tag is optional' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'malware',
        blob_hash   => $BLOB_HASH,
        event_id    => $EVID,
    );
    my @s = grep { $_->[0] eq 'server' } @{$event->tags};
    is(scalar @s, 0, 'no server tag when not provided');
};

###############################################################################
# L and l tags MAY be used (NIP-32)
###############################################################################

subtest 'NIP-32 labels MAY be included' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'profanity',
        labels      => [
            ['L', 'com.example.moderation'],
            ['l', 'hate-speech', 'com.example.moderation'],
        ],
    );
    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is(scalar @L, 1, 'L tag present');
    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is(scalar @l, 1, 'l tag present');
};

subtest 'report without NIP-32 labels' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'spam',
    );
    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is(scalar @L, 0, 'no L tag by default');
};

###############################################################################
# from_event() — parse a report
###############################################################################

subtest 'from_event: profile report' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1984, content => '',
        created_at => 1000,
        tags => [['p', $PUBKEY2, 'spam']],
    );
    my $info = Net::Nostr::Report->from_event($event);
    is($info->reported_pubkey, $PUBKEY2, 'reported pubkey');
    is($info->report_type, 'spam', 'report type');
    is($info->event_id, undef, 'no event id');
};

subtest 'from_event: note report' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1984, content => 'reason',
        created_at => 1000,
        tags => [
            ['e', $EVID, 'illegal'],
            ['p', $PUBKEY2],
        ],
    );
    my $info = Net::Nostr::Report->from_event($event);
    is($info->reported_pubkey, $PUBKEY2, 'reported pubkey');
    is($info->report_type, 'illegal', 'report type from e tag');
    is($info->event_id, $EVID, 'event id');
};

subtest 'from_event: blob report' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1984, content => '',
        created_at => 1000,
        tags => [
            ['x', $BLOB_HASH, 'malware'],
            ['e', $EVID, 'malware'],
            ['p', $PUBKEY2],
            ['server', 'https://example.com/file.ext'],
        ],
    );
    my $info = Net::Nostr::Report->from_event($event);
    is($info->blob_hash, $BLOB_HASH, 'blob hash');
    is($info->report_type, 'malware', 'report type from x tag');
    is($info->event_id, $EVID, 'event id');
    is($info->server, 'https://example.com/file.ext', 'server');
};

###############################################################################
# validate() — kind 1984 validation
###############################################################################

subtest 'validate: valid profile report' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1984, content => '',
        created_at => 1000,
        tags => [['p', $PUBKEY2, 'spam']],
    );
    ok(Net::Nostr::Report->validate($event), 'valid');
};

subtest 'validate: valid note report' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1984, content => '',
        created_at => 1000,
        tags => [['e', $EVID, 'illegal'], ['p', $PUBKEY2]],
    );
    ok(Net::Nostr::Report->validate($event), 'valid');
};

subtest 'validate: valid blob report' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1984, content => '',
        created_at => 1000,
        tags => [
            ['x', $BLOB_HASH, 'malware'],
            ['e', $EVID, 'malware'],
            ['p', $PUBKEY2],
            ['server', 'https://example.com/file.ext'],
        ],
    );
    ok(Net::Nostr::Report->validate($event), 'valid blob report');
};

subtest 'validate: wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => '',
        created_at => 1000,
        tags => [['p', $PUBKEY2, 'spam']],
    );
    like(dies { Net::Nostr::Report->validate($event) }, qr/kind/, 'wrong kind');
};

subtest 'validate: missing p tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1984, content => '',
        created_at => 1000,
        tags => [['e', $EVID, 'illegal']],
    );
    like(dies { Net::Nostr::Report->validate($event) }, qr/p tag/, 'missing p tag');
};

subtest 'validate: missing report type on p tag (profile-only report)' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1984, content => '',
        created_at => 1000,
        tags => [['p', $PUBKEY2]],
    );
    like(dies { Net::Nostr::Report->validate($event) },
        qr/report.type/i, 'missing report type');
};

subtest 'validate: x tag without e tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1984, content => '',
        created_at => 1000,
        tags => [['x', $BLOB_HASH, 'malware'], ['p', $PUBKEY2]],
    );
    like(dies { Net::Nostr::Report->validate($event) },
        qr/e tag/, 'x tag requires e tag');
};

###############################################################################
# report_filter() — subscription filter
###############################################################################

subtest 'report_filter: by reported pubkey' => sub {
    my $filter = Net::Nostr::Report->report_filter(
        reported_pk => $PUBKEY2,
    );
    is($filter->{kinds}, [1984], 'kind 1984');
    is($filter->{'#p'}, [$PUBKEY2], 'reported pubkey filter');
};

subtest 'report_filter: by authors' => sub {
    my $filter = Net::Nostr::Report->report_filter(
        authors => [$PUBKEY],
    );
    is($filter->{kinds}, [1984], 'kind 1984');
    is($filter->{authors}, [$PUBKEY], 'authors');
};

subtest 'report_filter: by event' => sub {
    my $filter = Net::Nostr::Report->report_filter(
        event_id => $EVID,
    );
    is($filter->{kinds}, [1984], 'kind 1984');
    is($filter->{'#e'}, [$EVID], 'event filter');
};

###############################################################################
# impersonation is profile-only (some types only make sense for profiles)
###############################################################################

subtest 'impersonation: profile-only report type' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        report_type => 'impersonation',
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][2], 'impersonation', 'impersonation on profile');
};

###############################################################################
# Report type on e tag vs p tag
###############################################################################

subtest 'note report: type goes on e tag, p tag has no type' => sub {
    my $event = Net::Nostr::Report->report(
        pubkey      => $PUBKEY,
        reported_pk => $PUBKEY2,
        event_id    => $EVID,
        report_type => 'profanity',
    );
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0][2], 'profanity', 'report type on e tag');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @{$p[0]}, 2, 'p tag has only 2 elements (no type)');
};

###############################################################################
# Negative validation: invalid hex identifiers
###############################################################################

subtest 'report rejects invalid reported_pk' => sub {
    like(
        dies { Net::Nostr::Report->report(
            pubkey => 'a' x 64, reported_pk => 'bad', report_type => 'spam',
        ) },
        qr/reported_pk must be 64-char lowercase hex/,
        'invalid reported_pk rejected'
    );
};

subtest 'report rejects invalid event_id' => sub {
    like(
        dies { Net::Nostr::Report->report(
            pubkey => 'a' x 64, reported_pk => 'b' x 64,
            report_type => 'spam', event_id => 'bad',
        ) },
        qr/event_id must be 64-char lowercase hex/,
        'invalid event_id rejected'
    );
};

done_testing;
