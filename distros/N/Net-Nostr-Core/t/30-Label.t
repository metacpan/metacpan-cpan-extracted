#!/usr/bin/perl

# Unit tests for Net::Nostr::Label
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Label;
use Net::Nostr::Event;

my $pubkey    = 'aa' x 32;
my $target_pk = 'bb' x 32;
my $event_id  = 'cc' x 32;
my $relay     = 'wss://relay.example.com';

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: create a label event' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $pubkey,
        namespace => 'com.example.ontology',
        labels    => ['VI-hum'],
        targets   => [['p', $target_pk, $relay]],
        content   => 'Explanation of the label',
    );
    is($event->kind, 1985, 'kind 1985');
};

subtest 'SYNOPSIS: build tags for self-reporting' => sub {
    my $L = Net::Nostr::Label->namespace_tag('ISO-639-1');
    my $l = Net::Nostr::Label->label_tag('en', 'ISO-639-1');
    is($L, ['L', 'ISO-639-1'], 'namespace tag');
    is($l, ['l', 'en', 'ISO-639-1'], 'label tag');
};

subtest 'SYNOPSIS: parse labels from event' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $pubkey,
        namespace => 'ISO-639-1',
        labels    => ['en'],
        targets   => [['e', $event_id]],
    );
    my $info = Net::Nostr::Label->from_event($event);
    my @namespaces = @{$info->namespaces};
    my @labels     = @{$info->labels};
    my @en_labels  = $info->labels_for('ISO-639-1');
    is(\@namespaces, ['ISO-639-1'], 'namespaces');
    is(\@en_labels, ['en'], 'labels for namespace');
};

subtest 'SYNOPSIS: has_label' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $pubkey,
        namespace => 'license',
        labels    => ['MIT'],
        targets   => [['e', $event_id]],
    );
    my $info = Net::Nostr::Label->from_event($event);
    ok($info->has_label('MIT', 'license'), 'has label');
};

subtest 'SYNOPSIS: label_filter' => sub {
    my $filter = Net::Nostr::Label->label_filter(
        namespace => 'license',
        labels    => ['MIT'],
    );
    is($filter->{kinds}, [1985], 'kind');
    is($filter->{'#L'}, ['license'], 'namespace');
    is($filter->{'#l'}, ['MIT'], 'label');
};

###############################################################################
# label() POD example
###############################################################################

subtest 'label: POD example' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $pubkey,
        namespace => 'license',
        labels    => ['MIT'],
        targets   => [['e', $event_id, $relay]],
        content   => 'optional explanation',
    );
    is($event->kind, 1985, 'kind');
    ok(length $event->content, 'has content');
};

###############################################################################
# namespace_tag() POD example
###############################################################################

subtest 'namespace_tag: POD example' => sub {
    my $tag = Net::Nostr::Label->namespace_tag('ISO-639-1');
    is($tag, ['L', 'ISO-639-1'], 'tag');
};

###############################################################################
# label_tag() POD examples
###############################################################################

subtest 'label_tag: with namespace' => sub {
    my $tag = Net::Nostr::Label->label_tag('en', 'ISO-639-1');
    is($tag, ['l', 'en', 'ISO-639-1'], 'tag with namespace');
};

subtest 'label_tag: without namespace' => sub {
    my $tag = Net::Nostr::Label->label_tag('spam');
    is($tag, ['l', 'spam'], 'tag without namespace');
};

###############################################################################
# from_event() POD example
###############################################################################

subtest 'from_event: POD example' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $pubkey,
        namespace => 'license',
        labels    => ['MIT'],
        targets   => [['e', $event_id]],
    );
    my $info = Net::Nostr::Label->from_event($event);
    my @ns      = @{$info->namespaces};
    my @labels  = @{$info->labels};
    my @targets = @{$info->targets};
    is(\@ns, ['license'], 'namespaces');
    is(scalar @targets, 1, 'one target');
};

###############################################################################
# has_label() POD examples
###############################################################################

subtest 'has_label: without namespace POD example' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey  => $pubkey,
        labels  => ['spam'],
        targets => [['e', $event_id]],
    );
    my $info = Net::Nostr::Label->from_event($event);
    ok($info->has_label('spam'), 'has spam label');
};

###############################################################################
# validate() POD example
###############################################################################

subtest 'validate: POD example' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $pubkey,
        namespace => 'license',
        labels    => ['MIT'],
        targets   => [['e', $event_id]],
    );
    ok(Net::Nostr::Label->validate($event), 'valid');
};

###############################################################################
# label_filter() POD example
###############################################################################

subtest 'label_filter: POD example' => sub {
    my $filter = Net::Nostr::Label->label_filter(
        namespace => 'license',
        labels    => ['MIT', 'GPL'],
        authors   => [$pubkey],
    );
    is($filter->{kinds}, [1985], 'kind');
    is($filter->{'#l'}, ['MIT', 'GPL'], 'labels');
    is($filter->{authors}, [$pubkey], 'authors');
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $event_id = 'cc' x 32;
    my $relay = 'wss://relay.example.com';
    my $label = Net::Nostr::Label->new(
        namespaces => ['ISO-639-1'],
        labels     => [['en', 'ISO-639-1']],
        targets    => [['e', $event_id, $relay]],
    );
    is $label->namespaces, ['ISO-639-1'];
    is $label->labels, [['en', 'ISO-639-1']];
    is $label->targets, [['e', $event_id, $relay]];
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Label->new(
            namespaces => ['ISO-639-1'],
            labels     => [['en', 'ISO-639-1']],
            bogus      => 'value',
        ) },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# Round-trip: label() -> from_event()
###############################################################################

subtest 'round-trip: label -> from_event' => sub {
    my $event = Net::Nostr::Label->label(
        pubkey    => $pubkey,
        namespace => 'com.example.ontology',
        labels    => ['VI-hum'],
        targets   => [['p', $target_pk, $relay]],
        content   => 'Explanation of the label',
    );

    my $info = Net::Nostr::Label->from_event($event);

    is($info->namespaces, ['com.example.ontology'], 'namespace preserved');
    is($info->labels, [['VI-hum', 'com.example.ontology']], 'label_value preserved');
    is($event->content, 'Explanation of the label', 'content preserved');
};

done_testing;
