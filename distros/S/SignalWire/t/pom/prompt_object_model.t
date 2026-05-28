#!/usr/bin/env perl
# t/pom/prompt_object_model.t
#
# Cross-language parity tests for SignalWire::POM::PromptObjectModel /
# SignalWire::POM::Section. Mirrors signalwire-python's
# tests/unit/pom/test_pom_object_model.py and additionally pins the exact
# byte-for-byte output of render_markdown / render_xml / to_json / to_yaml
# against the Python reference. Drift in either direction breaks this
# test.

use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('SignalWire::POM::Section');
use_ok('SignalWire::POM::PromptObjectModel');

# ============================================================
# 1. PromptObjectModel basics — port of TestPromptObjectModelBasics
# ============================================================
subtest 'empty pom has no sections' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    is_deeply($pom->sections, [], 'no sections');
};

subtest 'add_section returns Section instance' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    my $s = $pom->add_section(title => 'Greeting');
    isa_ok($s, 'SignalWire::POM::Section');
    is($s->title, 'Greeting', 'title preserved');
};

subtest 'add_section appears in sections' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'A');
    $pom->add_section(title => 'B');
    my @titles = map { $_->title } @{ $pom->sections };
    is_deeply(\@titles, ['A', 'B'], 'order preserved');
};

subtest 'find_section returns match' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'Greeting', body => 'Hello');
    my $s = $pom->find_section('Greeting');
    ok(defined $s, 'returned defined Section');
    is($s->title, 'Greeting', 'found by title');
};

subtest 'find_section returns undef when absent' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    is($pom->find_section('Nope'), undef, 'undef when missing');
};

subtest 'find_section recurses into subsections' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    my $s = $pom->add_section(title => 'Outer', body => 'b');
    $s->add_subsection(title => 'Inner', body => 'ib');
    my $found = $pom->find_section('Inner');
    ok(defined $found, 'recursive find succeeds');
    is($found->title, 'Inner', 'nested title found');
};

subtest 'render_markdown includes title and body' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'Greeting', body => 'Hello world');
    my $md = $pom->render_markdown;
    like($md, qr/Greeting/, 'title appears');
    like($md, qr/Hello world/, 'body appears');
};

subtest 'render_xml returns xml-shaped string' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'Greeting', body => 'Hi');
    my $xml = $pom->render_xml;
    like($xml, qr/<\?xml/, 'has xml declaration');
    like($xml, qr/<prompt>/, 'has prompt tag');
};

subtest 'to_hash returns arrayref' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'A', body => 'body-A');
    is(ref $pom->to_hash, 'ARRAY', 'to_hash returns arrayref');
};

subtest 'to_json round trip' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'A', body => 'body-A');
    my $json = $pom->to_json;
    like($json, qr/"A"/, 'json contains title');
    my $restored = SignalWire::POM::PromptObjectModel->from_json($json);
    my @titles = map { $_->title } @{ $restored->sections };
    is_deeply(\@titles, ['A'], 'titles round-trip');
};

# ============================================================
# 2. Section basics — port of TestSectionBasics
# ============================================================
subtest 'section with title only' => sub {
    my $s = SignalWire::POM::Section->new(title => 'Hello');
    is($s->title, 'Hello', 'title set');
};

subtest 'add_body REPLACES existing body' => sub {
    my $s = SignalWire::POM::Section->new(title => 'X', body => 'initial');
    $s->add_body('replacement');
    my $md = $s->render_markdown;
    like($md, qr/replacement/, 'new body appears');
    unlike($md, qr/initial/, 'old body is gone');
};

subtest 'add_bullets appends to existing list' => sub {
    my $s = SignalWire::POM::Section->new(title => 'X', body => 'b');
    $s->add_bullets(['one', 'two']);
    my $md = $s->render_markdown;
    like($md, qr/one/, 'bullet one rendered');
    like($md, qr/two/, 'bullet two rendered');
};

subtest 'add_subsection returns Section and is appended' => sub {
    my $parent = SignalWire::POM::Section->new(title => 'P', body => 'b');
    my $child = $parent->add_subsection(title => 'C', body => 'cb');
    isa_ok($child, 'SignalWire::POM::Section');
    is($child->title, 'C', 'child title');
    is(scalar @{ $parent->subsections }, 1, 'parent has one subsection');
    is($parent->subsections->[0]->title, 'C', 'subsection is the returned object');
};

subtest 'add_subsection requires title' => sub {
    my $parent = SignalWire::POM::Section->new(title => 'P', body => 'b');
    throws_ok { $parent->add_subsection(body => 'x') }
        qr/Subsections must have a title/,
        'add_subsection without title dies';
};

# ============================================================
# 3. Type validation
# ============================================================
subtest 'Section body must be a string' => sub {
    throws_ok { SignalWire::POM::Section->new(title => 'X', body => ['list']) }
        qr/body must be a string/,
        'arrayref body rejected';
};

subtest 'Section bullets must be a list' => sub {
    throws_ok { SignalWire::POM::Section->new(title => 'X', bullets => 'not a list') }
        qr/bullets must be a list/,
        'string bullets rejected';
};

subtest 'add_body rejects ref' => sub {
    my $s = SignalWire::POM::Section->new(title => 'X', body => 'b');
    throws_ok { $s->add_body(['a','b']) }
        qr/body must be a string/,
        'arrayref to add_body dies';
};

subtest 'add_section without title fails after first' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'A', body => 'b');
    throws_ok { $pom->add_section(body => 'c') }
        qr/Only the first section can have no title/,
        'second untitled section dies';
};

# ============================================================
# 4. Byte-for-byte parity with Python's render_markdown
# ============================================================
subtest 'markdown: simple section matches Python verbatim' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'Greeting', body => 'Hello world');
    is($pom->render_markdown, "## Greeting\n\nHello world\n",
        'simple section matches Python output exactly');
};

subtest 'markdown: section with bullets matches Python' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'Rules', body => 'Follow:', bullets => ['One', 'Two']);
    is($pom->render_markdown, "## Rules\n\nFollow:\n\n- One\n- Two\n",
        'bullets render with `-` prefix');
};

subtest 'markdown: nested subsections match Python' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    my $s = $pom->add_section(title => 'Main', body => 'Body');
    $s->add_subsection(title => 'Sub1', body => 'Sub body');
    $s->add_subsection(title => 'Sub2', bullets => ['b1','b2']);
    is($pom->render_markdown,
        "## Main\n\nBody\n\n### Sub1\n\nSub body\n\n### Sub2\n\n- b1\n- b2\n",
        'nested headings + bullets exact match');
};

subtest 'markdown: numbered top-level sections match Python' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'A', body => 'abody', numbered => 1);
    $pom->add_section(title => 'B', body => 'bbody');
    is($pom->render_markdown, "## 1. A\n\nabody\n\n## 2. B\n\nbbody\n",
        'auto-number when sibling marked numbered=1');
};

subtest 'markdown: numbered bullets match Python' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'X', body => 'xbody',
                      bullets => ['a','b'], numberedBullets => 1);
    is($pom->render_markdown, "## X\n\nxbody\n\n1. a\n2. b\n",
        'numberedBullets render with `1. 2.` prefix');
};

subtest 'markdown: untitled first section drops heading' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(body => 'no title body');
    is($pom->render_markdown, "no title body\n",
        'no `##` when title is undef');
};

subtest 'markdown: bullets-only section matches Python' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'Only', bullets => ['x']);
    is($pom->render_markdown, "## Only\n\n- x\n",
        'bullets without body render correctly');
};

subtest 'markdown: empty pom is empty string' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    is($pom->render_markdown, '', 'no sections => empty markdown');
};

# ============================================================
# 5. Byte-for-byte parity with Python's render_xml
# ============================================================
subtest 'xml: simple section matches Python verbatim' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'Greeting', body => 'Hello world');
    my $expected = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
                 . qq{<prompt>\n}
                 . qq{  <section>\n}
                 . qq{    <title>Greeting</title>\n}
                 . qq{    <body>Hello world</body>\n}
                 . qq{  </section>\n}
                 . qq{</prompt>};
    is($pom->render_xml, $expected, 'simple section XML matches Python exactly');
};

subtest 'xml: bullets match Python verbatim' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'Rules', body => 'Follow:', bullets => ['One', 'Two']);
    my $expected = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
                 . qq{<prompt>\n}
                 . qq{  <section>\n}
                 . qq{    <title>Rules</title>\n}
                 . qq{    <body>Follow:</body>\n}
                 . qq{    <bullets>\n}
                 . qq{      <bullet>One</bullet>\n}
                 . qq{      <bullet>Two</bullet>\n}
                 . qq{    </bullets>\n}
                 . qq{  </section>\n}
                 . qq{</prompt>};
    is($pom->render_xml, $expected, 'bullets XML matches Python exactly');
};

subtest 'xml: numbered bullets carry id attribute' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'X', body => 'xbody',
                      bullets => ['a','b'], numberedBullets => 1);
    my $expected = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
                 . qq{<prompt>\n}
                 . qq{  <section>\n}
                 . qq{    <title>X</title>\n}
                 . qq{    <body>xbody</body>\n}
                 . qq{    <bullets>\n}
                 . qq{      <bullet id="1">a</bullet>\n}
                 . qq{      <bullet id="2">b</bullet>\n}
                 . qq{    </bullets>\n}
                 . qq{  </section>\n}
                 . qq{</prompt>};
    is($pom->render_xml, $expected, 'numbered bullet id="N" matches Python');
};

subtest 'xml: nested subsections match Python verbatim' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    my $s = $pom->add_section(title => 'Main', body => 'Body');
    $s->add_subsection(title => 'Sub1', body => 'Sub body');
    $s->add_subsection(title => 'Sub2', bullets => ['b1','b2']);
    my $expected = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
                 . qq{<prompt>\n}
                 . qq{  <section>\n}
                 . qq{    <title>Main</title>\n}
                 . qq{    <body>Body</body>\n}
                 . qq{    <subsections>\n}
                 . qq{      <section>\n}
                 . qq{        <title>Sub1</title>\n}
                 . qq{        <body>Sub body</body>\n}
                 . qq{      </section>\n}
                 . qq{      <section>\n}
                 . qq{        <title>Sub2</title>\n}
                 . qq{        <bullets>\n}
                 . qq{          <bullet>b1</bullet>\n}
                 . qq{          <bullet>b2</bullet>\n}
                 . qq{        </bullets>\n}
                 . qq{      </section>\n}
                 . qq{    </subsections>\n}
                 . qq{  </section>\n}
                 . qq{</prompt>};
    is($pom->render_xml, $expected, 'nested XML matches Python exactly');
};

subtest 'xml: numbered top-level sections add prefix to title' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'A', body => 'abody', numbered => 1);
    $pom->add_section(title => 'B', body => 'bbody');
    my $expected = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
                 . qq{<prompt>\n}
                 . qq{  <section>\n}
                 . qq{    <title>1. A</title>\n}
                 . qq{    <body>abody</body>\n}
                 . qq{  </section>\n}
                 . qq{  <section>\n}
                 . qq{    <title>2. B</title>\n}
                 . qq{    <body>bbody</body>\n}
                 . qq{  </section>\n}
                 . qq{</prompt>};
    is($pom->render_xml, $expected, 'XML title prefix matches Python');
};

subtest 'xml: empty pom emits empty prompt' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    my $expected = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
                 . qq{<prompt>\n}
                 . qq{</prompt>};
    is($pom->render_xml, $expected, 'empty XML matches Python');
};

# ============================================================
# 6. JSON serialisation parity (exact byte match)
# ============================================================
subtest 'to_json key order matches Python' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    my $s = $pom->add_section(title => 'Test', body => 'Body', bullets => ['x','y']);
    $s->add_subsection(title => 'Sub', body => 'Sub body');

    my $expected = qq([\n)
                 . qq(  {\n)
                 . qq(    "title": "Test",\n)
                 . qq(    "body": "Body",\n)
                 . qq(    "bullets": [\n)
                 . qq(      "x",\n)
                 . qq(      "y"\n)
                 . qq(    ],\n)
                 . qq(    "subsections": [\n)
                 . qq(      {\n)
                 . qq(        "title": "Sub",\n)
                 . qq(        "body": "Sub body"\n)
                 . qq(      }\n)
                 . qq(    ]\n)
                 . qq(  }\n)
                 . qq(]);
    is($pom->to_json, $expected, 'to_json byte-equal to Python json.dumps(..., indent=2)');
};

# ============================================================
# 7. YAML serialisation (round-trip + bullets preservation)
#    Mirrors Python's TestPromptObjectModelYaml suite.
# ============================================================
subtest 'to_yaml returns string with section title and body' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'Greeting', body => 'Hello');
    my $y = $pom->to_yaml;
    ok(!ref($y), 'returns scalar string');
    like($y, qr/Greeting/, 'title appears');
    like($y, qr/Hello/, 'body appears');
};

subtest 'from_yaml round trip preserves bullets' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    $pom->add_section(title => 'A', body => 'body-A', bullets => ['x','y']);
    my $y = $pom->to_yaml;
    my $restored = SignalWire::POM::PromptObjectModel->from_yaml($y);
    my @titles = map { $_->title } @{ $restored->sections };
    is_deeply(\@titles, ['A'], 'title round-trips');
    my $a = $restored->find_section('A');
    ok(defined $a, 'found A after yaml round-trip');
    is_deeply($a->bullets, ['x','y'], 'bullets survive yaml round-trip');
};

subtest 'from_yaml accepts arrayref input (parsed yaml)' => sub {
    my $data = [{ title => 'B', body => 'y' }];
    my $pom = SignalWire::POM::PromptObjectModel->from_yaml($data);
    ok(defined $pom->find_section('B'), 'arrayref input accepted');
};

subtest 'to_yaml exact format matches Python' => sub {
    my $pom = SignalWire::POM::PromptObjectModel->new;
    my $s = $pom->add_section(title => 'Test', body => 'Body', bullets => ['x','y']);
    $s->add_subsection(title => 'Sub', body => 'Sub body');
    my $expected = "- title: Test\n"
                 . "  body: Body\n"
                 . "  bullets:\n"
                 . "  - x\n"
                 . "  - y\n"
                 . "  subsections:\n"
                 . "  - title: Sub\n"
                 . "    body: Sub body\n";
    is($pom->to_yaml, $expected, 'YAML output matches Python verbatim');
};

# ============================================================
# 8. add_pom_as_subsection
# ============================================================
subtest 'add_pom_as_subsection by title' => sub {
    my $main = SignalWire::POM::PromptObjectModel->new;
    $main->add_section(title => 'Outer', body => 'Body');
    my $sub_pom = SignalWire::POM::PromptObjectModel->new;
    $sub_pom->add_section(title => 'Inner', body => 'i');
    $main->add_pom_as_subsection('Outer', $sub_pom);
    my $outer = $main->find_section('Outer');
    is(scalar @{ $outer->subsections }, 1, 'one subsection after merge');
    is($outer->subsections->[0]->title, 'Inner', 'merged title');
};

subtest 'add_pom_as_subsection by section object' => sub {
    my $main = SignalWire::POM::PromptObjectModel->new;
    my $outer = $main->add_section(title => 'Outer', body => 'Body');
    my $sub_pom = SignalWire::POM::PromptObjectModel->new;
    $sub_pom->add_section(title => 'Inner', body => 'i');
    $main->add_pom_as_subsection($outer, $sub_pom);
    is($outer->subsections->[0]->title, 'Inner', 'merge by Section ref works');
};

subtest 'add_pom_as_subsection dies when target title missing' => sub {
    my $main = SignalWire::POM::PromptObjectModel->new;
    my $sub_pom = SignalWire::POM::PromptObjectModel->new;
    $sub_pom->add_section(title => 'I', body => 'i');
    throws_ok { $main->add_pom_as_subsection('Nope', $sub_pom) }
        qr/No section with title 'Nope' found/,
        'missing title dies';
};

# ============================================================
# 9. AgentBase->pom integration: returns PromptObjectModel
# ============================================================
subtest 'AgentBase->pom returns PromptObjectModel object' => sub {
    require SignalWire::Agent::AgentBase;
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pom_agent');
    $agent->prompt_add_section('Greeting', 'Hello');
    my $pom = $agent->pom;
    isa_ok($pom, 'SignalWire::POM::PromptObjectModel');
    my @titles = map { $_->title } @{ $pom->sections };
    is_deeply(\@titles, ['Greeting'], 'sections wrapped');
    is($pom->sections->[0]->body, 'Hello', 'body preserved');
};

subtest 'AgentBase->pom returns undef when use_pom is false' => sub {
    require SignalWire::Agent::AgentBase;
    my $agent = SignalWire::Agent::AgentBase->new(name => 'no_pom', use_pom => 0);
    is($agent->pom, undef, 'undef returned when use_pom is off');
};

subtest 'AgentBase->pom is a fresh object each call (no caller leak)' => sub {
    require SignalWire::Agent::AgentBase;
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pom_iso');
    $agent->prompt_add_section('Original', 'Body');
    my $pom = $agent->pom;
    # Mutating the returned POM must not leak back into the agent.
    $pom->add_section(title => 'Injected', body => 'leaked');
    $pom->sections->[0]->title('Hijacked');
    my $fresh = $agent->pom;
    is(scalar @{ $fresh->sections }, 1, 'caller add_section did not leak');
    is($fresh->sections->[0]->title, 'Original',
        'caller mutation of section title did not leak');
};

done_testing;
