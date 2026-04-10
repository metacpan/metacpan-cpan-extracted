#!/usr/bin/perl

# NIP-32 conformance tests: Labeling

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Label;
use Net::Nostr::Event;

my $PUBKEY  = 'aa' x 32;
my $PUBKEY2 = 'bb' x 32;
my $RELAY   = 'wss://relay.example.com';
my $EVID    = 'cc' x 32;

###############################################################################
# L tag — label namespace
###############################################################################

subtest 'namespace_tag: basic' => sub {
    my $tag = Net::Nostr::Label->namespace_tag('com.example.ontology');
    is($tag, ['L', 'com.example.ontology'], 'L tag');
};

subtest 'namespace_tag: # prefix for association' => sub {
    my $tag = Net::Nostr::Label->namespace_tag('#t');
    is($tag, ['L', '#t'], 'L tag with # prefix');
};

subtest 'namespace_tag: ugc namespace' => sub {
    my $tag = Net::Nostr::Label->namespace_tag('ugc');
    is($tag, ['L', 'ugc'], 'ugc namespace');
};

###############################################################################
# l tag — label
###############################################################################

subtest 'label_tag: with namespace mark' => sub {
    my $tag = Net::Nostr::Label->label_tag('VI-hum', 'com.example.ontology');
    is($tag, ['l', 'VI-hum', 'com.example.ontology'], 'l tag with mark');
};

subtest 'label_tag: without namespace mark (ugc implied)' => sub {
    my $tag = Net::Nostr::Label->label_tag('spam');
    is($tag, ['l', 'spam'], 'l tag without mark');
};

subtest 'label_tag: with # namespace' => sub {
    my $tag = Net::Nostr::Label->label_tag('permies', '#t');
    is($tag, ['l', 'permies', '#t'], 'l tag with # namespace');
};

###############################################################################
# label() — create kind 1985 event
###############################################################################

subtest 'label: basic kind 1985 event' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'com.example.ontology',
        labels    => ['VI-hum'],
        targets   => [['p', $PUBKEY2, $RELAY]],
    );
    is($event->kind, 1985, 'kind 1985');
    is($event->pubkey, $PUBKEY, 'pubkey');

    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is(scalar @L, 1, 'one L tag');
    is($L[0][1], 'com.example.ontology', 'namespace');

    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is(scalar @l, 1, 'one l tag');
    is($l[0], ['l', 'VI-hum', 'com.example.ontology'], 'label with mark');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 1, 'one target');
};

subtest 'label: multiple labels in same namespace' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'license',
        labels    => ['MIT', 'OSI-approved'],
        targets   => [['e', $EVID, $RELAY]],
    );
    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is(scalar @l, 2, 'two l tags');
    is($l[0][2], 'license', 'first label mark');
    is($l[1][2], 'license', 'second label mark');
};

subtest 'label: multiple targets' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => '#t',
        labels    => ['permies'],
        targets   => [
            ['p', $PUBKEY, $RELAY],
            ['p', $PUBKEY2, $RELAY],
        ],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 2, 'two targets');
};

subtest 'label: content for explanation' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'com.example.ontology',
        labels    => ['VI-hum'],
        targets   => [['p', $PUBKEY2]],
        content   => 'This account posts violent content',
    );
    is($event->content, 'This account posts violent content', 'content');
};

subtest 'label: requires pubkey' => sub {
    like(dies {
        Net::Nostr::Label->label(
            namespace => 'test',
            labels    => ['x'],
            targets   => [['e', $EVID]],
        );
    }, qr/pubkey/, 'requires pubkey');
};

subtest 'label: requires targets' => sub {
    like(dies {
        Net::Nostr::Label->label(
            pubkey    => $PUBKEY,
            namespace => 'test',
            labels    => ['x'],
        );
    }, qr/target/, 'requires targets');

    like(dies {
        Net::Nostr::Label->label(
            pubkey    => $PUBKEY,
            namespace => 'test',
            labels    => ['x'],
            targets   => [],
        );
    }, qr/target/, 'requires non-empty targets');
};

subtest 'label: requires labels' => sub {
    like(dies {
        Net::Nostr::Label->label(
            pubkey    => $PUBKEY,
            namespace => 'test',
            targets   => [['e', $EVID]],
        );
    }, qr/label/, 'requires labels');
};

subtest 'label: without namespace (ugc implied)' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey  => $PUBKEY,
        labels  => ['spam'],
        targets => [['e', $EVID]],
    );
    is($event->kind, 1985, 'kind 1985');

    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is(scalar @L, 0, 'no L tag when ugc implied');

    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is($l[0], ['l', 'spam'], 'l tag without mark');
};

###############################################################################
# Spec examples — exact JSON from NIP-32
###############################################################################

subtest 'spec example: pubkeys associated with permies topic' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => '#t',
        labels    => ['permies'],
        targets   => [
            ['p', $PUBKEY, $RELAY],
            ['p', $PUBKEY2, $RELAY],
        ],
    );
    is($event->kind, 1985, 'kind 1985');
    my @tags = @{$event->tags};

    my @L = grep { $_->[0] eq 'L' } @tags;
    is($L[0][1], '#t', 'L tag #t');

    my @l = grep { $_->[0] eq 'l' } @tags;
    is($l[0], ['l', 'permies', '#t'], 'l tag permies');

    my @p = grep { $_->[0] eq 'p' } @tags;
    is(scalar @p, 2, 'two p targets');
};

subtest 'spec example: violence report with ontology' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'com.example.ontology',
        labels    => ['VI-hum'],
        targets   => [
            ['p', $PUBKEY, $RELAY],
            ['p', $PUBKEY2, $RELAY],
        ],
    );
    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is($L[0][1], 'com.example.ontology', 'ontology namespace');

    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is($l[0], ['l', 'VI-hum', 'com.example.ontology'], 'ontology label');
};

subtest 'spec example: moderation suggestion' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'nip28.moderation',
        labels    => ['approve'],
        targets   => [['e', $EVID, $RELAY]],
    );
    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is($l[0], ['l', 'approve', 'nip28.moderation'], 'moderation label');

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0], ['e', $EVID, $RELAY], 'event target');
};

subtest 'spec example: license assignment' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'license',
        labels    => ['MIT'],
        targets   => [['e', $EVID, $RELAY]],
    );
    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is($l[0], ['l', 'MIT', 'license'], 'license label');
};

subtest 'spec example: self-labeling with ISO 3166-2' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => "It's beautiful here in Milan!",
        tags    => [
            ['L', 'ISO-3166-2'],
            ['l', 'IT-MI', 'ISO-3166-2'],
        ],
    );
    is($event->kind, 1, 'kind 1 (self-report)');

    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is($L[0][1], 'ISO-3166-2', 'ISO namespace');

    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is($l[0], ['l', 'IT-MI', 'ISO-3166-2'], 'location label');
};

subtest 'spec example: self-labeling with ISO-639-1 language' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'English text',
        tags    => [
            ['L', 'ISO-639-1'],
            ['l', 'en', 'ISO-639-1'],
        ],
    );
    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is($l[0], ['l', 'en', 'ISO-639-1'], 'language label');
};

###############################################################################
# from_event() — extract labels from any event
###############################################################################

subtest 'from_event: extract namespaces and labels' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [
            ['L', 'com.example.ontology'],
            ['l', 'VI-hum', 'com.example.ontology'],
            ['p', $PUBKEY2, $RELAY],
        ],
    );
    my $info = Net::Nostr::Label->from_event($event);
    is($info->namespaces, ['com.example.ontology'], 'namespaces');
    is($info->labels, [['VI-hum', 'com.example.ontology']], 'labels');
    is(scalar @{$info->targets}, 1, 'one target');
};

subtest 'from_event: multiple namespaces' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [
            ['L', 'content-warning'],
            ['l', 'reason', 'content-warning'],
            ['L', 'social.nos.ontology'],
            ['l', 'NS-nud', 'social.nos.ontology'],
            ['e', $EVID],
        ],
    );
    my $info = Net::Nostr::Label->from_event($event);
    is(scalar @{$info->namespaces}, 2, 'two namespaces');
    is(scalar @{$info->labels}, 2, 'two labels');
};

subtest 'from_event: self-reported labels on non-1985 event' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'text',
        created_at => 1000,
        tags => [
            ['L', 'ISO-639-1'],
            ['l', 'en', 'ISO-639-1'],
        ],
    );
    my $info = Net::Nostr::Label->from_event($event);
    is($info->namespaces, ['ISO-639-1'], 'namespace from self-report');
    is($info->labels, [['en', 'ISO-639-1']], 'label from self-report');
};

subtest 'from_event: labels without namespace (ugc implied)' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [
            ['l', 'spam'],
            ['e', $EVID],
        ],
    );
    my $info = Net::Nostr::Label->from_event($event);
    is(scalar @{$info->namespaces}, 0, 'no explicit namespace');
    is($info->labels, [['spam']], 'label without mark');
};

###############################################################################
# labels_for() — get labels for a specific namespace
###############################################################################

subtest 'labels_for: filter by namespace' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [
            ['L', 'content-warning'],
            ['l', 'reason', 'content-warning'],
            ['L', 'social.nos.ontology'],
            ['l', 'NS-nud', 'social.nos.ontology'],
            ['e', $EVID],
        ],
    );
    my $info = Net::Nostr::Label->from_event($event);
    my @cw = $info->labels_for('content-warning');
    is(\@cw, ['reason'], 'content-warning labels');

    my @ont = $info->labels_for('social.nos.ontology');
    is(\@ont, ['NS-nud'], 'ontology labels');

    my @none = $info->labels_for('nonexistent');
    is(\@none, [], 'no labels for unknown namespace');
};

###############################################################################
# has_label() — check for specific label
###############################################################################

subtest 'has_label: with namespace' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [
            ['L', 'license'],
            ['l', 'MIT', 'license'],
            ['e', $EVID],
        ],
    );
    my $info = Net::Nostr::Label->from_event($event);
    ok($info->has_label('MIT', 'license'), 'has MIT in license namespace');
    ok(!$info->has_label('GPL', 'license'), 'no GPL');
    ok(!$info->has_label('MIT', 'other'), 'wrong namespace');
};

subtest 'has_label: without namespace' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [
            ['l', 'spam'],
            ['e', $EVID],
        ],
    );
    my $info = Net::Nostr::Label->from_event($event);
    ok($info->has_label('spam'), 'has spam label');
    ok(!$info->has_label('ham'), 'no ham label');
};

###############################################################################
# validate() — kind 1985 validation
###############################################################################

subtest 'validate: valid kind 1985 with e target' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [
            ['L', 'license'],
            ['l', 'MIT', 'license'],
            ['e', $EVID, $RELAY],
        ],
    );
    ok(Net::Nostr::Label->validate($event), 'valid with e target');
};

subtest 'validate: valid kind 1985 with p target' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [['l', 'spam'], ['p', $PUBKEY2]],
    );
    ok(Net::Nostr::Label->validate($event), 'valid with p target');
};

subtest 'validate: valid with a target' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [['l', 'x'], ['a', "34550:$PUBKEY2:test"]],
    );
    ok(Net::Nostr::Label->validate($event), 'valid with a target');
};

subtest 'validate: valid with r target' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [['l', 'x'], ['r', 'wss://relay.com']],
    );
    ok(Net::Nostr::Label->validate($event), 'valid with r target');
};

subtest 'validate: valid with t target' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [['l', 'x'], ['t', 'nostr']],
    );
    ok(Net::Nostr::Label->validate($event), 'valid with t target');
};

subtest 'validate: wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => '',
        created_at => 1000,
        tags => [['l', 'x'], ['e', $EVID]],
    );
    like(dies { Net::Nostr::Label->validate($event) }, qr/kind/, 'wrong kind');
};

subtest 'validate: missing target tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [['L', 'license'], ['l', 'MIT', 'license']],
    );
    like(dies { Net::Nostr::Label->validate($event) }, qr/target/, 'no targets');
};

subtest 'validate: l tag mark must match L tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [
            ['L', 'license'],
            ['l', 'MIT', 'other-namespace'],
            ['e', $EVID],
        ],
    );
    like(dies { Net::Nostr::Label->validate($event) },
        qr/mark.*match|namespace/i, 'l mark must match L');
};

###############################################################################
# label_filter() — subscription filter
###############################################################################

subtest 'label_filter: by namespace' => sub {
    my $filter = Net::Nostr::Label->label_filter(
        namespace => 'com.example.ontology',
    );
    is($filter->{kinds}, [1985], 'kind 1985');
    is($filter->{'#L'}, ['com.example.ontology'], 'namespace filter');
};

subtest 'label_filter: by label' => sub {
    my $filter = Net::Nostr::Label->label_filter(
        labels => ['MIT'],
    );
    is($filter->{kinds}, [1985], 'kind 1985');
    is($filter->{'#l'}, ['MIT'], 'label filter');
};

subtest 'label_filter: by namespace and label' => sub {
    my $filter = Net::Nostr::Label->label_filter(
        namespace => 'license',
        labels    => ['MIT', 'GPL'],
    );
    is($filter->{kinds}, [1985], 'kind 1985');
    is($filter->{'#L'}, ['license'], 'namespace');
    is($filter->{'#l'}, ['MIT', 'GPL'], 'labels');
};

subtest 'label_filter: by authors' => sub {
    my $filter = Net::Nostr::Label->label_filter(
        namespace => 'license',
        authors   => [$PUBKEY],
    );
    is($filter->{authors}, [$PUBKEY], 'authors filter');
};

###############################################################################
# l tag MUST include mark matching L tag
###############################################################################

subtest 'l tag mark matches L tag in label()' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'com.example',
        labels    => ['test'],
        targets   => [['e', $EVID]],
    );
    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is($l[0][2], 'com.example', 'l tag mark matches namespace');
};

###############################################################################
# Fully qualified labels
###############################################################################

subtest 'fully qualified labels within namespace' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'com.example.vocabulary',
        labels    => ['com.example.vocabulary:my-label'],
        targets   => [['e', $EVID]],
    );
    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is($l[0][1], 'com.example.vocabulary:my-label', 'fully qualified label');
    is($l[0][2], 'com.example.vocabulary', 'namespace mark present');
};

###############################################################################
# Target tag types (e, p, a, r, t)
###############################################################################

subtest 'all target tag types supported' => sub {
    for my $type (qw(e p a r t)) {
        my $event = Net::Nostr::Label->label(
            pubkey    => $PUBKEY,
            namespace => 'test',
            labels    => ['x'],
            targets   => [[$type, 'value']],
        );
        my @targets = grep { $_->[0] eq $type } @{$event->tags};
        is(scalar @targets, 1, "$type target supported");
    }
};

###############################################################################
# L tags starting with # — association
###############################################################################

subtest 'L tag with # prefix associates target with label value' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => '#t',
        labels    => ['permies'],
        targets   => [['p', $PUBKEY2, $RELAY]],
    );
    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is($L[0][1], '#t', 'L tag starts with #');
};

###############################################################################
# Default content is empty string
###############################################################################

subtest 'default content is empty string' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'test',
        labels    => ['x'],
        targets   => [['e', $EVID]],
    );
    is($event->content, '', 'empty content by default');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'multiple target types in one event' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'test',
        labels    => ['x'],
        targets   => [
            ['e', $EVID, $RELAY],
            ['p', $PUBKEY2],
            ['t', 'nostr'],
        ],
    );
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @e, 1, 'e target');
    is(scalar @p, 1, 'p target');
    is(scalar @t, 1, 't target');
};

###############################################################################
# Relay hint SHOULD be included for e and p tags
###############################################################################

subtest 'relay hint SHOULD be included for e target' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'license',
        labels    => ['MIT'],
        targets   => [['e', $EVID, $RELAY]],
    );
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0][2], $RELAY, 'relay hint on e tag');
};

subtest 'relay hint SHOULD be included for p target' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => '#t',
        labels    => ['permies'],
        targets   => [['p', $PUBKEY2, $RELAY]],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][2], $RELAY, 'relay hint on p tag');
};

###############################################################################
# Publishers SHOULD limit to single namespace
###############################################################################

subtest 'single namespace per event (SHOULD)' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $PUBKEY,
        namespace => 'license',
        labels    => ['MIT'],
        targets   => [['e', $EVID]],
    );
    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is(scalar @L, 1, 'label() produces single namespace');
};

###############################################################################
# Self-reporting on various event kinds
###############################################################################

subtest 'self-reporting on kind 30023 (article)' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 30023,
        content => 'Article about permaculture',
        tags    => [
            ['d', 'permaculture-101'],
            ['L', 'ISO-3166-2'],
            ['l', 'IT-MI', 'ISO-3166-2'],
        ],
    );
    my $info = Net::Nostr::Label->from_event($event);
    is($info->namespaces, ['ISO-3166-2'], 'namespace on article');
    is($info->labels, [['IT-MI', 'ISO-3166-2']], 'label on article');
    # For non-1985 events, labels refer to the event itself
    is(scalar @{$info->targets}, 0, 'no target tags (self-report)');
};

###############################################################################
# l tag without L but with mark (SHOULD still include mark)
###############################################################################

subtest 'l tag SHOULD include mark even without L tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1985, content => '',
        created_at => 1000,
        tags => [
            ['l', 'spam', 'ugc'],
            ['e', $EVID],
        ],
    );
    my $info = Net::Nostr::Label->from_event($event);
    is($info->labels, [['spam', 'ugc']], 'mark present without L tag');
    ok($info->has_label('spam', 'ugc'), 'found by namespace');
};

done_testing;
