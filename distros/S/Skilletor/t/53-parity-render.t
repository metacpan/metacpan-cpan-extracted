#!/usr/bin/env perl
# Render parity: the reference's render.ts (build, executables, rendersEmpty) and
# Skilletor::Render on the same source trees and contexts – output bytes, executable bits, empty
# renders and error messages, word for word. The context reaches both as the same JSON text, so
# the port reads it with its own JSON model (ordered objects, JSON::MaybeXS booleans, null), as a
# config gives it vars. Needs node and the TypeScript tree (src/) beside lib/.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use IPC::Open2 qw( open2 );
use Path::Tiny qw( path tempdir );
use Scalar::Util qw( blessed );
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text );
use Skilletor::JSON qw( js_parse js_sort_keys js_stringify );
use Skilletor::Render qw( build executables renders_empty );

my $runner = path( $FindBin::Bin, '..', 'maint', 'ts-run.mjs' );
my $src_ts = path( $FindBin::Bin, '..', 'src', 'render.ts' );
plan skip_all => 'needs the skilletor checkout (src/) and maint/ts-run.mjs' unless $runner->exists && $src_ts->exists;
plan skip_all => 'needs node' unless grep { -x path( $_, 'node' ) } split /:/, $ENV{PATH} // '';
plan skip_all => 'needs the reference\'s node_modules' unless path( $FindBin::Bin, '..', 'node_modules', 'nunjucks' )->exists;

# The request goes as JSON text, so both sides parse the very same context.
sub ts {
  my ( $json, %opt ) = @_;
  my $pid = open2( my $out, my $in, 'node', "$runner" );
  binmode $in, ':raw';
  print {$in} encode_text($json);
  close $in;
  local $/;
  my $text = <$out>;
  waitpid $pid, 0;
  die 'ts-run failed: '.( $text // '' ) unless defined $text && length $text;
  my $answer = js_parse( decode_utf8_lossy($text) );
  die 'ts-run: '.$answer->{error} if defined $answer->{error};
  return $answer->{result};
}

my $CONTEXT = '{"vars": {}, "scope": "user", "harness": "claude", "target": {"dir": "/home/u/.claude"}, '
  .'"host": {"name": "box", "os": "linux"}, "user": {"name": "getty", "home": "/home/u"}, '
  .'"item": {"name": "demo", "type": "skill", "source": "shared"}}';

# A context with `vars` (JSON text) and other fields replaced.
sub context {
  my ( $vars, %more ) = @_;
  my $c = $CONTEXT;
  $c =~ s/"vars": \{\}/"vars": $vars/ if defined $vars;
  $c =~ s/\}\z/, "$_": $more{$_}}/ for sort keys %more;
  $c =~ s/"scope": "user"/"scope": "project"/ if $more{project};
  return $c;
}

my $tmp = tempdir->realpath;
my $n   = 0;

# The port's answer, in the shape of the reference's.
sub perl_render {
  my ( $item, $dir, $context ) = @_;
  my $out;
  unless ( eval { $out = build( $item, $dir, $context ); 1 } ) {
    my $err = $@;
    return { error => ( blessed $err && $err->can('message') ? $err->message : "$err" ), name => ( blessed $err && $err->can('name') ? $err->name : ref $err ) };
  }
  return {
    output       => [ map { [ $_->[0], unpack( 'H*', $_->[1] ) ] } @$out ],
    executables  => [ js_sort_keys( keys %{ executables( $item, $dir ) } ) ],
    rendersEmpty => renders_empty( $item, $out ) ? 1 : 0,
  };
}

# One case: the source tree (path => text, or { bytes, mode }), the item (JSON text), the context.
# Its tree is written now; both engines render it in run_cases.
my @cases;

sub render_case {
  my ( $name, %c ) = @_;
  my $dir = path( $tmp, 'case'.++$n );
  for my $rel ( sort keys %{ $c{files} } ) {
    my $f = $c{files}{$rel};
    my $p = path( $dir, $rel );
    $p->parent->mkpath;
    $p->spew_raw( ref $f ? $f->{bytes} // encode_text( $f->{text} ) : encode_text($f) );
    chmod $f->{mode}, "$p" if ref $f && $f->{mode};
  }
  push @cases, { %c, name => $name, dir => "$dir", context => $c{context} // $CONTEXT };
}

# The reference renders every case so far in one run, then each case compares the port's answer.
sub run_cases {
  my @run = splice @cases;
  my $ts = ts( '{"op": "render", "cases": ['
      .join( ', ', map { '{"item": '.$_->{item}.', "sourceDir": '.js_stringify( $_->{dir} ).', "context": '.$_->{context}.'}' } @run ).']}' );
  for my $i ( 0 .. $#run ) {
    my ( $c, $want ) = ( $run[$i], $ts->[$i] );
    my $perl = perl_render( js_parse( $c->{item} ), $c->{dir}, js_parse( $c->{context} ) );
    local $TODO = $c->{todo};
    subtest $c->{name} => sub {
      if ( defined $want->{error} ) {
        is( $perl->{error}, $want->{error}, 'the same error' );
        is( $perl->{name},  $want->{name},  'of the same class' );
        return;
      }
      ok( !defined $perl->{error}, 'renders' ) or diag $perl->{error};
      is_deeply( $perl->{output}, [ map { [@$_] } @{ $want->{output} } ], 'the same files, the same bytes' )
        or diag explain { perl => [ map { [ $_->[0], decode_utf8_lossy( pack 'H*', $_->[1] ) ] } @{ $perl->{output} // [] } ],
                          ts   => [ map { [ $_->[0], decode_utf8_lossy( pack 'H*', $_->[1] ) ] } @{ $want->{output} } ] };
      is_deeply( $perl->{executables}, [ @{ $want->{executables} } ], 'the same executables' );
      is( $perl->{rendersEmpty}, $want->{rendersEmpty} ? 1 : 0, 'the same empty verdict' );
    };
  }
}

my $SKILL = '{"type": "skill", "name": "demo", "dir": "skills/demo", "files": ["skills/demo/SKILL.md.njk"]}';

render_case( 'an include, an import and its macro from the source root',
  files => {
    'snippets/shared.md'       => "SHARED {{ vars.foo }}\n",
    'snippets/macros.njk'      => '{% macro hi(n) %}hi {{ n }}{% endmacro %}',
    'skills/demo/SKILL.md.njk' => join( "\n",
      '{% import "snippets/macros.njk" as m %}{% from "snippets/macros.njk" import hi %}',
      'foo={{ vars.foo }}', '{% if vars.k %}K-ON{% endif %}', '{% for x in vars.list %}[{{ x }}]{% endfor %}',
      '{% include "snippets/shared.md" %}', '{{ m.hi("there") }} {{ hi(item.name) }}', '' ),
  },
  item    => $SKILL,
  context => context('{"foo": "bar", "k": true, "list": [1, 2]}'),
);

render_case( 'a template extends a base in the source root',
  files => {
    'layouts/base.njk'         => "[{% block body %}base{% endblock %}]\n",
    'skills/demo/SKILL.md.njk' => '{% extends "layouts/base.njk" %}{% block body %}{{ scope }} {{ super() }}{% endblock %}',
  },
  item => $SKILL,
);

render_case( 'an undefined variable: the throwOnUndefined error',
  files => { 'skills/demo/SKILL.md.njk' => "---\ndescription: d\n---\nfoo={{ vars.missing }}\n" },
  item  => $SKILL,
);

render_case( 'an undefined variable in an included file',
  files => { 'skills/demo/SKILL.md.njk' => "A\n{% include \"parts/p.md\" %}\n", 'parts/p.md' => "x\n {{ vars.nope }}" },
  item  => $SKILL,
);

render_case( 'a member of the undefined project (user scope)',
  files => { 'skills/demo/SKILL.md.njk' => "{{ project.name }}" },
  item  => $SKILL,
);

render_case( 'an include that escapes the source root',
  files => { 'skills/demo/SKILL.md.njk' => 'A {% include "../../../etc/passwd" %} B' },
  item  => $SKILL,
);

render_case( 'an absolute include outside the source root',
  files => { 'skills/demo/SKILL.md.njk' => '{% include "/etc/passwd" %}' },
  item  => $SKILL,
);

render_case( 'an import that escapes the source root',
  files => { 'skills/demo/SKILL.md.njk' => "{% import \"../m.njk\" as m %}A\n" },
  item  => $SKILL,
);

render_case( 'a ./ name is relative to the source root, not the including template',
  files => { 'skills/demo/SKILL.md.njk' => '{% include "./part.md" %}|{% include "skills/../part.md" %}', 'part.md' => 'ROOT', 'skills/demo/part.md' => 'BESIDE' },
  item  => $SKILL,
);

render_case( 'a missing include',
  files => { 'skills/demo/SKILL.md.njk' => '{% include "nothere.md" %}' },
  item  => $SKILL,
);

render_case( 'a directory is no template',
  files => { 'skills/demo/SKILL.md.njk' => '{% include "skills" %}' },
  item  => $SKILL,
);

render_case( 'a syntax error',
  files => { 'skills/demo/SKILL.md.njk' => "line\nA {% if %} B" },
  item  => $SKILL,
);

render_case( 'an unknown filter',
  files => { 'skills/demo/SKILL.md.njk' => '{{ 1 | nosuch }}' },
  item  => $SKILL,
);

render_case( 'UTF-8: non-ASCII text, vars and UTF-16 lengths',
  files => {
    'skills/demo/SKILL.md.njk' => "---\ndescription: Grüße\n---\nGrüße {{ vars.who }} – {{ \"é€😀\" }} {{ \"😀\" | length }} {{ vars.who | length }} "
      .'{{ vars.who | upper }} {{ ("😀x" | list)[0] }}|{{ "😀"[0] }}{{ "😀"[1] }}'."\n",
  },
  item    => $SKILL,
  context => context('{"who": "Ärger 😀"}'),
);

render_case( 'ill-formed UTF-8 in a template and in a copied file',
  files => {
    'skills/demo/SKILL.md.njk' => { bytes => "a\xFF\xC3(b {{ scope }}\n" },
    'skills/demo/logo.png'     => { bytes => "\x89PNG\x00\xFF\x10\x42" },
  },
  item => '{"type": "skill", "name": "demo", "dir": "skills/demo", "files": ["skills/demo/SKILL.md.njk", "skills/demo/logo.png"]}',
);

render_case( 'JSON values: null, booleans, numbers, nested objects in their order',
  files => {
    'skills/demo/SKILL.md.njk' => join( "\n",
      '{{ vars.n is defined }} {{ vars.n is none }} {{ vars.u is defined }} {{ vars.n | default("d", true) }}',
      '{% if vars.f %}F{% else %}not-f{% endif %} {% if vars.t %}T{% endif %} {{ vars.t }} {{ vars.f }} {{ vars.t == true }}',
      '{{ vars.i }} {{ vars.x }} {{ vars.i + 1 }} {{ vars.s + 1 }} {{ vars.big }} {{ vars.i is number }} {{ vars.s is string }} {{ 10 / 3 }}',
      '{% for k, v in vars.o %}{{ k }}={{ v }};{% endfor %} {{ vars.o | dump }} {{ vars.l }} {{ vars.l | length }}',
      '{% for k, v in vars.o %}{% if loop.last %}last={{ k }}{% endif %}{% endfor %} {{ vars.o.b.z }} {{ vars.o }}', '' ),
  },
  item    => $SKILL,
  context => context( '{"n": null, "t": true, "f": false, "i": 10, "x": 1.5, "s": "5.40", "big": 12345678901234567890, '
    .'"o": {"b": {"z": [true, null]}, "a": 2, "10": "ten", "9": "nine"}, "l": [1, "x", false, null, {"k": 1}]}' ),
);

render_case( 'a null output is the throwOnUndefined error',
  files => { 'skills/demo/SKILL.md.njk' => 'x{{ vars.n }}y' },
  item  => $SKILL,
  context => context('{"n": null}'),
);

render_case( 'the context objects: item, host, user, target, project',
  files => {
    'skills/demo/SKILL.md.njk' => '{% for o in [item, host, user, target, project] %}{% for k, v in o %}{{ k }}={{ v }};{% endfor %}|{% endfor %}'
      .' {{ scope }} {{ harness }} {{ project is defined }}',
  },
  item    => $SKILL,
  context => context( undef, project => '{"dir": "/p/app", "name": "app", "git_remote": "https://example.invalid/app.git"}' ),
);

render_case( 'no project in the user scope',
  files => { 'skills/demo/SKILL.md.njk' => '{{ project is defined }} {% if project %}P{% else %}none{% endif %}' },
  item  => $SKILL,
);

render_case( 'filters, tests and globals a skill may use',
  files => {
    'skills/demo/SKILL.md.njk' => join( "\n",
      '{{ user.name | upper }} {{ host.os | title }} {{ target.dir | replace("/", "_") }} {{ "<b>" }} {{ "<b>" | escape }}',
      '{{ [3, 1, 2] | sort | join("-") }} {{ 7 // 2 }} {{ 2 ** 10 }} {{ range(3) | join }} {{ "  pad  " | trim }}',
      '{{ "a b c" | wordcount }} {{ "hello world" | capitalize }} {{ "x" | indent(2, true) }} {{ "long text here" | truncate(6) }}',
      '{{ vars.missing | default("dflt") }} {% if vars.missing %}no{% endif %} {{ vars.o | dictsort | join(",") }}',
      '{% set s %}set {{ item.type }}{% endset %}{{ s }} {% raw %}{{ raw }}{% endraw %} {{ "a&b" | urlencode }}',
      '{% for x in [1, 2, 3] %}{{ loop.index }}{% if not loop.last %},{% endif %}{% endfor %} {{ ("yes" if vars.t else "no") }}', '' ),
  },
  item    => $SKILL,
  context => context('{"o": {"b": 1, "a": 2}, "t": true}'),
);

render_case( 'whitespace control, comments, CRLF and a BOM',
  files => { 'skills/demo/SKILL.md.njk' => "\x{FEFF}---\r\nname: demo\r\n---\r\na\n{%- if true -%}\n  b  \n{%- endif %}\n\n{# c #}\nd {{ scope }}\r\n" },
  item  => $SKILL,
);

render_case( 'an executable template passes its bit to what it renders',
  files => {
    'skills/demo/SKILL.md.njk' => "---\ndescription: d\n---\nrun it\n",
    'skills/demo/run.sh.njk'   => { text => "#!/bin/sh\necho {{ item.name }}\n", mode => 0755 },
    'skills/demo/tool.sh'      => { text => "#!/bin/sh\n", mode => 0755 },
    'skills/demo/plain.md.njk' => { text => "{{ scope }}\n", mode => 0644 },
  },
  item => '{"type": "skill", "name": "demo", "dir": "skills/demo", "files": ["skills/demo/SKILL.md.njk", "skills/demo/run.sh.njk", "skills/demo/tool.sh", "skills/demo/plain.md.njk"]}',
);

render_case( 'a rule gated off renders empty: frontmatter only',
  files => { 'rules/k8s.md.njk' => "---\ndescription: K\n---\n{% if vars.kubernetes %}Use kubectl.{% endif %}\n  \n" },
  item    => '{"type": "rule", "name": "k8s", "files": ["rules/k8s.md.njk"]}',
  context => context('{"kubernetes": false}'),
);

render_case( 'the same rule gated on is not empty',
  files => { 'rules/k8s.md.njk' => "---\ndescription: K\n---\n{% if vars.kubernetes %}Use kubectl.{% endif %}\n" },
  item    => '{"type": "rule", "name": "k8s", "files": ["rules/k8s.md.njk"]}',
  context => context('{"kubernetes": true}'),
);

render_case( 'renders empty: whitespace the way JavaScript counts it',
  files => {
    'plugins/p/skills/demo/SKILL.md.njk' => "\x{FEFF}\x{A0}\n---\npaths: x\n---\n\x{2028}\x{3000}\t\n",
    'plugins/p/skills/demo/ref.md'       => 'REF',
  },
  item => '{"type": "skill", "name": "demo", "dir": "plugins/p/skills/demo", "files": ["plugins/p/skills/demo/SKILL.md.njk", "plugins/p/skills/demo/ref.md"]}',
);

render_case( 'renders empty: U+0085 is no JavaScript whitespace',
  files => { 'agents/a.md.njk' => "---\nname: a\n---\n\x{85}\n" },
  item  => '{"type": "agent", "name": "a", "files": ["agents/a.md.njk"]}',
);

render_case( 'renders empty: an unclosed frontmatter is text',
  files => { 'rules/r.md.njk' => "---\npaths: x\n" },
  item  => '{"type": "rule", "name": "r", "files": ["rules/r.md.njk"]}',
);

render_case( 'an agent in a plugin directory installs under agents/',
  files   => { 'plugins/p/agents/a.md.njk' => "---\nname: a\n---\n{{ item.type }} {{ item.name }}\n" },
  item    => '{"type": "agent", "name": "a", "dir": "plugins/p/agents", "files": ["plugins/p/agents/a.md.njk"]}',
  context => $CONTEXT =~ s/"name": "demo", "type": "skill"/"name": "a", "type": "agent"/r,
);

run_cases();

render_case( 'an include of a file with a syntax error',
  files => { 'skills/demo/SKILL.md.njk' => "A\n{% include \"p.md\" %}", 'p.md' => '{% for %}' },
  item  => $SKILL,
);
run_cases();

done_testing;
