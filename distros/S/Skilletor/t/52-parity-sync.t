#!/usr/bin/env perl
# Sync parity on one machine: the reference and Skilletor::Engine sync the same home and project
# from the same pristine state, and must leave the same bytes – installed files, lock, .gitignore
# blocks, .worktreeinclude, settings.json and the state records `check` reads (render-inputs.json
# with its hash, sources-read.json, unreached.json) – and the same reports; each one's `check`
# must accept what the other synced. Needs node and the TypeScript tree beside perl/.
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
use Skilletor::JSON qw( js_parse js_sort_keys js_stringify js_type );

my $runner = path( $FindBin::Bin, '..', 'maint', 'ts-run.mjs' );
my $src_ts = path( $FindBin::Bin, '..', '..', 'src', 'engine.ts' );
plan skip_all => 'needs the skilletor checkout (../src) and maint/ts-run.mjs' unless $runner->exists && $src_ts->exists;
plan skip_all => 'needs node' unless grep { -x path( $_, 'node' ) } split /:/, $ENV{PATH} // '';
plan skip_all => 'needs the reference\'s node_modules' unless path( $FindBin::Bin, '..', '..', 'node_modules', 'nunjucks' )->exists;

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

sub same_json {
  my ( $perl, $ts, $name ) = @_;
  is( js_stringify( canonical( js_parse( js_stringify($perl) ) ), 2 ), js_stringify( canonical($ts), 2 ), $name );
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
} );
my $crew = files( "$root/crew", 'skills/tool/SKILL.md' => skill('tool'), 'skilletor.json' => '{"vars": {"from": "source", "n": 10}}' );

path( $home, '.claude' )->mkpath;
path( $home, '.claude.json' )->spew_raw("{}\n");
write_json( "$home/.claude/skilletor.json", {
  sources => { shared => { git => $remote->{url} }, crew => { local => $crew } },
  install => { skills => [ 'lint@shared', 'taken@shared' ], agents => ['rev@shared'], rules => ['nomatch-*@shared'] },
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
  install => { skills => [ 'tool@crew', 'deploy@team' ], bundles => ['team@shared'] },
  vars    => { team => 'core' },
} );
write_json( "$proj/.claude/skilletor.local.json", { vars => { who => 'me' } } );

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

my $ts_sync = ts( { op => 'sync', %$req } );
my %after_ts = (
  home    => tree( $home, '.claude/skilletor' ),
  project => tree( $proj, '.git' ),
  state   => state_files("$home/.claude/skilletor"),
);
ok( scalar( keys %{ $after_ts{state} } ) >= 3, 'the reference recorded its state' )
  or diag join ', ', sort keys %{ $after_ts{state} };

subtest 'the port checks and reports what the reference synced' => sub {
  my $perl_check = $engine->check;
  only_local_moved( $perl_check, 'the port' );
  same_json( $perl_check, ts( { op => 'check', %$req } ), 'the same check report' );
  same_json( $engine->status, ts( { op => 'status', %$req } ), 'the same status report' );
};

restore();
my $perl_sync = $engine->sync;

subtest 'the port syncs as the reference did, byte for byte' => sub {
  same_json( $perl_sync, $ts_sync, 'the same sync report' );
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
  my $ts_check = ts( { op => 'check', %$req } );
  only_local_moved( $ts_check, 'the reference' );
  same_json( $engine->check, $ts_check, 'the same check report' );
  same_json( $engine->sync, ts( { op => 'sync', %$req } ), 'a second sync of each: the same report' );
};

done_testing;
