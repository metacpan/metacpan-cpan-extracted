#!/usr/bin/env perl
# Sync parity on one machine: the reference and Skilletor::Engine sync the same home and project
# from the same pristine state, and must leave the same bytes – installed files, lock, .gitignore
# blocks, .worktreeinclude, settings.json and the state records `check` reads (render-inputs.json
# with its hash, sources-read.json, unreached.json), rendered templates with the default host and
# user – and the same reports, down to the bytes `--json` prints (k171); each one's `check` must
# accept what the other synced. Needs node and the TypeScript tree (src/) beside lib/.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json bare_remote git_ok );

use IPC::Open2 qw( open2 );
use Path::Tiny qw( path tempdir );
use Skilletor::Engine;
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text );
use Skilletor::JSON qw( js_ordered js_parse js_sort_keys js_stringify js_type );
use Skilletor::Report qw( report_json );

my $runner = path( $FindBin::Bin, '..', 'maint', 'ts-run.mjs' );
my $src_ts = path( $FindBin::Bin, '..', 'src', 'engine.ts' );
plan skip_all => 'needs the skilletor checkout (src/) and maint/ts-run.mjs' unless $runner->exists && $src_ts->exists;
plan skip_all => 'needs node' unless grep { -x path( $_, 'node' ) } split /:/, $ENV{PATH} // '';
plan skip_all => 'needs the reference\'s node_modules' unless path( $FindBin::Bin, '..', 'node_modules', 'nunjucks' )->exists;

sub ts {
  my ( $req ) = @_;
  my $pid = open2( my $out, my $in, 'node', "$runner" );
  binmode $in, ':raw';
  print {$in} encode_text( js_stringify($req) );
  close $in;
  local $/;
  my $text = <$out>;
  waitpid $pid, 0;
  die 'ts-run failed: '.( $text // '' ) unless defined $text && length $text;
  my $answer = js_parse( decode_utf8_lossy($text) );
  die 'ts-run: '.$answer->{error} if defined $answer->{error};
  return $answer->{result};
}

# Keys sorted, arrays sorted by their elements' canonical text: the reference resolves sources in
# parallel, so its warnings come in completion order.
sub canonical {
  my ( $v ) = @_;
  my $type = js_type($v);
  if ( $type eq 'array' ) {
    my @texts = map { js_stringify( canonical($_) ) } @$v;
    return [ map { js_parse($_) } js_sort_keys(@texts) ];
  }
  return { map { ( $_ => canonical( $v->{$_} ) ) } keys %$v } if $type eq 'object';
  return $v;
}

# The reference's report of a sync, check or status as `--json` prints it: { text, report }.
sub ts_report {
  my ( $op, $req ) = @_;
  my $text = ts( { op => $op, %$req, json => JSON::MaybeXS::true() } );
  return { text => $text, report => js_parse($text) };
}

# The same report: the same data, then the same bytes – key order, every array in its order.
sub same_report {
  my ( $perl, $ts, $name ) = @_;
  is( js_stringify( canonical( js_parse( js_stringify($perl) ) ), 2 ), js_stringify( canonical( $ts->{report} ), 2 ), "$name: the same data" );
  is( report_json($perl), $ts->{text}, "$name: the same --json bytes" );
}

sub files {
  my ( $root, %files ) = @_;
  for my $rel ( keys %files ) {
    my $p = path( $root, $rel );
    $p->parent->mkpath;
    $p->spew_raw( encode_text( $files{$rel} ) );
  }
  return "$root";
}

# Every file under $dir as { rel => bytes }; directories named in $skip (relative) left out.
sub tree {
  my ( $dir, @skip ) = @_;
  my %out;
  return \%out unless -d $dir;
  path($dir)->visit(
    sub {
      my ( $p ) = @_;
      my $rel = $p->relative($dir)->stringify;
      return if grep { $rel eq $_ || index( $rel, $_.'/' ) == 0 } @skip;
      $out{$rel} = $p->slurp_raw if -f $p && !-l $p;
    },
    { recurse => 1 },
  );
  return \%out;
}

sub state_files { tree( $_[0], 'cache', 'sync.lock' ) }

sub skill { "---\ndescription: $_[0]\n---\nbody of $_[0]\n" }

# A check after a complete sync: no drift and no render inputs to redo; of the sources only the
# `local` one counts as changed, as a local source always does (spec §4.4).
sub only_local_moved {
  my ( $check, $who ) = @_;
  ok( !grep( { exists $check->{$_} } qw( targetsChanged layoutChanged declaredChanged varsChanged error ) ), "$who: no drift" )
    or diag explain $check;
  is_deeply( [ sort map { "$_->{scope}:$_->{name}" } grep { $_->{changed} } @{ $check->{sources} } ], ['project:crew'],
    "$who: only the local source counts as changed" );
}

my $tmp  = tempdir;
my $root = $tmp->realpath;
my $home = "$root/home";
my $proj = "$root/project";
path( $root, 'remote' )->mkpath;
my $remote = bare_remote("$root/remote");
$remote->{commit}->( {
  'skills/lint/SKILL.md'  => skill('lint'),
  'skills/taken/SKILL.md' => skill('taken'),
  'agents/rev.md'         => "---\nname: rev\ndescription: reviews\nbriefing:\n  skills: [lint, nowhere]\n---\nReview.\n",
  'rules/style.md'        => "Short sentences.\n",
  'bundles/team.yaml'     => "description: The team set\nskills: [lint]\nrules: [style]\nvars: {from: bundle}\n",
  # Templates (spec §5): the user's vars as the template sees them, a main file gated off in the
  # user scope (renders-empty).
  'skills/greet/SKILL.md.njk' => "---\ndescription: greets\n---\n{{ vars | dump }} {{ project is defined }} {{ scope }}/{{ harness }}\n",
  'rules/gated.md.njk'        => "{% if project is defined %}Only in a project.{% endif %}\n",
} );
# A template with the whole context, an include from the source root, and one that fails.
my $crew = files(
  "$root/crew",
  'skills/tool/SKILL.md'       => skill('tool'),
  'skilletor.json'             => '{"vars": {"from": "source", "n": 10}}',
  'skills/hello/SKILL.md.njk'  => "---\ndescription: hello for {{ project.name }}\n---\n"
    ."{{ item.type }} {{ item.name }} from {{ item.source }}, {{ scope }}/{{ harness }} into {{ target.dir }}\n"
    ."{{ project.dir }} {{ project.git_remote }}\n{{ user.name }} {{ user.home }} on {{ host.name }} ({{ host.os }})\n"
    ."{{ vars | dump }}\n{% for k, v in vars %}{{ k }}={{ v | dump }};{% endfor %}\n{% include \"snippets/sig.md\" %}\n",
  'snippets/sig.md'            => "\x{2013} {{ vars.from }}, n={{ vars.n + 1 }}",
  'skills/broken/SKILL.md.njk' => "---\ndescription: broken\n---\n{{ vars.nope }}\n",
);

path( $home, '.claude' )->mkpath;
path( $home, '.claude.json' )->spew_raw("{}\n");
write_json( "$home/.claude/skilletor.json", {
  sources => { shared => { git => $remote->{url} }, crew => { local => $crew } },
  install => { skills => [ 'lint@shared', 'taken@shared', 'greet@shared' ], agents => ['rev@shared'], rules => [ 'nomatch-*@shared', 'gated@shared' ] },
  vars    => { level => 1, nested => { b => [ 1, 'x', JSON::MaybeXS::true() ], a => undef }, 10 => 'ten', 9 => 'nine' },
} );
# A hand-written skill where an item goes: a lasting conflict, recorded as unreached.
files( "$home/.claude", 'skills/taken/SKILL.md' => "mine\n" );
write_json( "$home/.claude/plugins/installed_plugins.json",
  { version => 2, plugins => { 'skilletor@getty' => [ { scope => 'user', installPath => "$home/.claude/plugins/cache/getty/skilletor/0.7.0" } ] } } );
write_json( "$home/.claude/plugins/known_marketplaces.json", { getty => { source => { source => 'github', repo => 'Getty/marketplace' } } } );

path( $proj, '.claude' )->mkpath;
git_ok( $proj, 'init', '-q', '-b', 'main' );
git_ok( $proj, 'remote', 'add', 'origin', 'https://example.invalid/team/app.git' );    # a render input
write_json( "$proj/.claude/skilletor.json", {
  sources => { team => { git => 'https://example.invalid/team/skills.git' } },    # project-only, untrusted
  install => { skills => [ 'tool@crew', 'deploy@team', 'hello@crew', 'broken@crew' ], bundles => ['team@shared'] },
  vars    => { team => 'core' },
} );
write_json( "$proj/.claude/skilletor.local.json", { vars => { who => 'me' } } );

# What earlier syncs recorded of scopes that are gone – a removed checkout, a key a relative
# --project-dir made – beside a live scope's (k254; unreached.json and render-inputs.json, k255):
# both engines drop the same, the live one stays.
my $other = "$root/other/.claude/skilletor.lock.json";
path($other)->parent->mkpath;
path($other)->spew_raw("{}\n");
my %earlier = (
  'sources-read.json'  => js_ordered( s => js_ordered( version => 'git:1', kind => 'git', address => 'https://example.invalid/s.git' ) ),
  'unreached.json'     => ['missing:skills/x@s'],
  'render-inputs.json' => 'sha256:1',
);
write_json( "$home/.claude/skilletor/$_",
  js_ordered( "$root/gone/.claude/skilletor.lock.json" => $earlier{$_}, '.claude/skilletor.lock.json' => $earlier{$_}, $other => $earlier{$_} ) )
  for sort keys %earlier;

# The pristine machine, to start each engine's sync from; the project's .git stays as it is.
my %pristine = ( home => tree($home), project => tree( $proj, '.git' ) );

sub restore {
  for my $which (qw( home project )) {
    my $dir = $which eq 'home' ? $home : $proj;
    for my $c ( grep { $_->basename ne '.git' } path($dir)->children ) { -d $c && !-l $c ? $c->remove_tree( { safe => 0 } ) : $c->remove }
    for my $rel ( keys %{ $pristine{$which} } ) {
      my $p = path( $dir, $rel );
      $p->parent->mkpath;
      $p->spew_raw( $pristine{$which}{$rel} );
    }
  }
}

my $req = { home => $home, projectDir => $proj, scope => 'all' };
my $engine = Skilletor::Engine->new(
  home             => $home,
  project_dir      => $proj,
  codex_home       => "$home/.codex",
  is_git_work_tree => sub { 0 },
  git_tracked      => sub { [] },
);

my $ts_sync_json = ts_report( sync => $req );
my $ts_sync = $ts_sync_json->{report};
my %after_ts = (
  home    => tree( $home, '.claude/skilletor' ),
  project => tree( $proj, '.git' ),
  state   => state_files("$home/.claude/skilletor"),
);
ok( scalar( keys %{ $after_ts{state} } ) >= 3, 'the reference recorded its state' )
  or diag join ', ', sort keys %{ $after_ts{state} };
for my $file ( sort keys %earlier ) {
  my $recorded = js_parse( decode_utf8_lossy( $after_ts{state}{$file} ) );
  is_deeply( [ keys %$recorded ], [ $other, "$home/.claude/skilletor.lock.json", "$proj/.claude/skilletor.lock.json" ],
    "$file: the reference dropped the records of scopes that are gone, kept the live one" );
  is( js_stringify( $recorded->{$other} ), js_stringify( $earlier{$file} ), "$file: the live one as it was" );
}
# The templates did render there, so the same bytes here are the same rendering.
like( decode_utf8_lossy( $after_ts{project}{'.claude/skills/hello/SKILL.md'} // '' ),
  qr/^skill hello from crew, project\/claude into \Q$proj\E\/\.claude\n.*^\x{2013} source, n=11$/ms, 'the reference rendered the templates' );
is_deeply( [ map { $_->{key} } map { @{ $_->{skipped} } } @{ $ts_sync->{scopes} } ], ['rules/gated'], 'skipped one that renders empty' );
is( scalar( grep { /\Atemplate error in skill broken: / } map { @{ $_->{warnings} } } @{ $ts_sync->{scopes} } ), 1,
  'and warned of the one that fails' );

subtest 'the port checks and reports what the reference synced' => sub {
  my $perl_check = $engine->check;
  only_local_moved( $perl_check, 'the port' );
  same_report( $perl_check, ts_report( check => $req ), 'the same check report' );
  same_report( $engine->status, ts_report( status => $req ), 'the same status report' );
};

restore();
my $perl_sync = $engine->sync;

subtest 'the port syncs as the reference did, byte for byte' => sub {
  same_report( $perl_sync, $ts_sync_json, 'the same sync report' );
  my %after_perl = (
    home    => tree( $home, '.claude/skilletor' ),
    project => tree( $proj, '.git' ),
    state   => state_files("$home/.claude/skilletor"),
  );
  for my $which (qw( home project state )) {
    is_deeply( [ sort keys %{ $after_perl{$which} } ], [ sort keys %{ $after_ts{$which} } ], "$which: the same files" );
    for my $rel ( sort keys %{ $after_ts{$which} } ) {
      is( $after_perl{$which}{$rel}, $after_ts{$which}{$rel}, "$which: $rel" );
    }
  }
};

subtest 'the reference checks what the port synced' => sub {
  my $ts_check = ts_report( check => $req );
  only_local_moved( $ts_check->{report}, 'the reference' );
  same_report( $engine->check, $ts_check, 'the same check report' );
  same_report( $engine->sync, ts_report( sync => $req ), 'a second sync of each: the same report' );
};

done_testing;
