use strict;
use warnings;
use Test2::V0;
use PAGI::Headers;

subtest 'empty + construction from pairs' => sub {
    my $h = PAGI::Headers->new;
    is $h->is_empty, 1, 'new is empty';
    is $h->count, 0, 'count 0';
    is $h->to_pairs, [], 'no pairs';

    my $h2 = PAGI::Headers->new([['Content-Type','text/plain'],['X-Foo','a'],['X-Foo','b']]);
    is $h2->is_empty, 0, 'not empty';
    is $h2->count, 3, 'three header lines';
};

subtest 'case-insensitive reads, original casing preserved' => sub {
    my $h = PAGI::Headers->new([['Content-Type','text/plain'],['X-Foo','a'],['X-Foo','b']]);
    is $h->get('content-type'), 'text/plain', 'get is case-insensitive';
    is $h->get('X-FOO'), 'b', 'get returns the LAST value';
    is [$h->get_all('x-foo')], ['a','b'], 'get_all returns all values in order';
    is $h->has('CONTENT-TYPE'), 1, 'has is case-insensitive';
    is $h->has('x-bar'), 0, 'has false for absent';
    is [$h->names], ['Content-Type','X-Foo'], 'names: distinct, insertion order, ORIGINAL casing';
    is [@{$h}], [['Content-Type','text/plain'],['X-Foo','a'],['X-Foo','b']], '@{} overload yields the pairs';
};

subtest '@{} overload is a copy (read-only): pushing onto it does not mutate' => sub {
    my $h = PAGI::Headers->new([['X-A','1']]);
    push @{$h}, ['X-B','2'];          # pushes onto the COPY
    is $h->count, 1, 'container unchanged by pushing onto the deref';
    is $h->has('x-b'), 0, 'no X-B leaked in';
};

subtest 'set replaces, add appends, set_default is set-if-absent' => sub {
    my $h = PAGI::Headers->new([['X-Foo','a'],['X-Foo','b']]);
    $h->set('X-Foo','only');
    is [$h->get_all('x-foo')], ['only'], 'set replaces all values';
    $h->add('X-Foo','more');
    is [$h->get_all('x-foo')], ['only','more'], 'add appends';
    $h->set_default('X-Foo','ignored');
    is [$h->get_all('x-foo')], ['only','more'], 'set_default no-op when present';
    $h->set_default('X-New','fresh');
    is $h->get('x-new'), 'fresh', 'set_default sets when absent';
    is $h->set('X-Foo','z'), $h, 'writers return self for chaining';
};

subtest 'remove returns values; clear empties' => sub {
    my $h = PAGI::Headers->new([['Set-Cookie','a=1'],['X-Keep','k'],['Set-Cookie','b=2']]);
    is [$h->remove('set-cookie')], ['a=1','b=2'], 'remove returns the removed values';
    is $h->has('set-cookie'), 0, 'header gone after remove';
    is [$h->names], ['X-Keep'], 'others preserved';
    $h->clear;
    is $h->is_empty, 1, 'clear empties';
};

subtest 'remove_content_headers' => sub {
    my $h = PAGI::Headers->new([
        ['Content-Type','text/html'], ['Content-Length','5'], ['X-Keep','k'],
    ]);
    my $removed = $h->remove_content_headers;
    isa_ok $removed, ['PAGI::Headers'], 'returns a PAGI::Headers of the removed set';
    is [$removed->names], ['Content-Type','Content-Length'], 'removed content-* headers';
    is $h->has('content-type'), 0, 'content headers gone from original';
    is $h->has('x-keep'), 1, 'non-content preserved';
};

subtest 'dehop strips the fixed set AND Connection-named headers' => sub {
    my $h = PAGI::Headers->new([
        ['Connection','keep-alive, X-Secret'], ['Transfer-Encoding','chunked'],
        ['X-Secret','sensitive'], ['X-Keep','k'],
    ]);
    $h->dehop;
    is $h->has('connection'), 0, 'Connection stripped';
    is $h->has('transfer-encoding'), 0, 'fixed hop-by-hop stripped';
    is $h->has('x-secret'), 0, 'header NAMED by Connection is also stripped';
    is $h->has('x-keep'), 1, 'end-to-end header kept';
};

subtest 'output forms + clone independence' => sub {
    my $h = PAGI::Headers->new([['X-A','1'],['X-B','2']]);
    is $h->to_pairs, [['X-A','1'],['X-B','2']], 'to_pairs';
    is [$h->flatten], ['X-A','1','X-B','2'], 'flatten is a flat list';
    is $h->to_string, "X-A: 1\r\nX-B: 2\r\n", 'to_string wire form, insertion order';
    my $c = $h->clone;
    $c->set('X-A','changed');
    is $h->get('x-a'), '1', 'clone is independent of the original';
};

subtest 'to_hash: flat (last value) and multi (arrayref), case-insensitively grouped' => sub {
    my $h = PAGI::Headers->new([
        ['Content-Type','text/html'],
        ['X-Multi','a'], ['X-Multi','b'],
    ]);
    is $h->to_hash, { 'Content-Type' => 'text/html', 'X-Multi' => 'b' },
        'flat to_hash: one value per name, last wins (mirrors get)';
    is $h->to_hash(1), { 'Content-Type' => ['text/html'], 'X-Multi' => ['a','b'] },
        'to_hash(1): arrayref of all values per name (mirrors get_all)';

    my $mixed = PAGI::Headers->new([['X-Foo','1'],['x-foo','2']]);
    is $mixed->to_hash, { 'X-Foo' => '2' },
        'mixed-case same name grouped under first-seen casing, last value';
    is $mixed->to_hash(1), { 'X-Foo' => ['1','2'] },
        'to_hash(1) groups all case-insensitive matches';

    my $empty = PAGI::Headers->new->to_hash;
    is $empty, {}, 'empty container -> empty hash';
};

subtest 'get returns the LAST value and never comma-joins' => sub {
    my $h = PAGI::Headers->new;
    $h->add('Vary','Accept');
    $h->add('Vary','Accept-Encoding');
    is $h->get('vary'), 'Accept-Encoding', 'get returns the last value';
    isnt $h->get('vary'), 'Accept, Accept-Encoding',
        'get does NOT comma-join (divergence from HTTP::Headers / Mojo::Headers)';
    is [$h->get_all('vary')], ['Accept','Accept-Encoding'], 'get_all keeps values separate, in order';
};

subtest 'header values are opaque bytes: CR/LF/NUL/whitespace pass through' => sub {
    # The container never sanitizes. The SERVER rejects injection bytes when it
    # emits a response (PAGI::Spec::Www, "Response Start"); these pin the
    # container's deliberate pass-through so nobody "hardens" it here and breaks
    # the facts/policy boundary.
    my $h = PAGI::Headers->new;
    $h->add('X-Evil', "a\r\nInjected: 1");
    is $h->get('x-evil'), "a\r\nInjected: 1", 'CR/LF preserved verbatim -- no fold, no croak';
    like $h->to_string, qr/X-Evil: a\r\nInjected: 1\r\n/,
        'to_string emits the raw bytes (debug-only, unsafe -- server validates the wire)';

    $h->set('X-Nul', "a\x00b");
    is $h->get('x-nul'), "a\x00b", 'NUL preserved verbatim';

    $h->set('X-Ws', '  spaced  ');
    is $h->get('x-ws'), '  spaced  ', 'leading/trailing whitespace preserved (no normalization)';
};

subtest 'empty-string and zero values are real values, not absence' => sub {
    my $h = PAGI::Headers->new;
    $h->add('X-Empty', '');
    is $h->has('x-empty'), 1, 'empty-value header is present';
    is $h->get('x-empty'), '', 'empty value retrievable as ""';
    $h->add('X-Zero', '0');
    is $h->get('x-zero'), '0', 'zero value round-trips (not treated as false/absent)';
    like $h->to_string, qr/X-Zero: 0\r\n/, 'zero survives serialization';
};

subtest 'duplicate names are retained as distinct pairs' => sub {
    my $h = PAGI::Headers->new([['Set-Cookie','a=1'],['Set-Cookie','b=2']]);
    is $h->to_pairs, [['Set-Cookie','a=1'],['Set-Cookie','b=2']], 'dups kept in to_pairs';
    is [$h->flatten], ['Set-Cookie','a=1','Set-Cookie','b=2'], 'dups kept in flatten';
    is [$h->names], ['Set-Cookie'], 'names collapses to distinct';
    is $h->count, 2, 'count reflects lines, not distinct names';
};

subtest 'mutation order: remove-then-add appends at the end; set on absent adds' => sub {
    my $h = PAGI::Headers->new([['X-A','1'],['X-B','2']]);
    $h->remove('X-A');
    $h->add('X-A','3');
    is [map { $_->[0] } @{$h->to_pairs}], ['X-B','X-A'], 're-added header lands at the end (insertion order)';

    my $e = PAGI::Headers->new;
    $e->set('X-New','v');
    is $e->get('x-new'), 'v', 'set on an absent name just adds it';
};

subtest 'remove of an absent header is a harmless no-op' => sub {
    my $h = PAGI::Headers->new([['X-A','1']]);
    is [$h->remove('X-Absent')], [], 'returns empty list';
    is $h->to_pairs, [['X-A','1']], 'container unchanged';
};

subtest 'construction round-trip; clone independent in both directions' => sub {
    my $pairs = [['Content-Type','text/html'],['Set-Cookie','a'],['Set-Cookie','b']];
    my $round_trip = PAGI::Headers->new($pairs)->to_pairs;
    is $round_trip, $pairs, 'new(pairs)->to_pairs round-trips identically';

    my $h = PAGI::Headers->new([['X-A','1']]);
    my $c = $h->clone;
    $h->set('X-A','changed-original');   # mutate the ORIGINAL (existing test mutates the clone)
    is $c->get('x-a'), '1', 'clone unaffected when the original is mutated';
};

subtest 'undef header value is rejected (fail loud, never stored)' => sub {
    my $h = PAGI::Headers->new([['X-A','1']]);
    like dies { $h->add('X-B', undef) }, qr/value must be defined/, 'add rejects undef value';
    like dies { $h->set('X-C', undef) }, qr/value must be defined/, 'set rejects undef value';
    like dies { $h->set_default('X-D', undef) }, qr/value must be defined/, 'set_default rejects undef value';
    is $h->to_pairs, [['X-A','1']], 'nothing was stored by the rejected calls';
    like dies { $h->get(undef) }, qr/header name required/, 'the undef-NAME guard still holds';
};

done_testing;
