#!/usr/bin/env perl
# Resolve parity beyond the shared conformance cases: the reference's resolveItems and
# Skilletor::Resolver on the same homes, projects, sources and locks – what the lock keeps
# offering, invalid names, bundle var conflicts, failed scans, bundle entries of other sources
# served by an untrusted one. Needs node and the TypeScript tree beside perl/.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json bare_remote );

use IPC::Open2 qw( open2 );
use Path::Tiny qw( path tempdir );
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text );
use Skilletor::JSON qw( js_parse js_sort_keys js_stringify js_type );
use Skilletor::Resolver;
use Skilletor::State;
use Time::HiRes ();

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
  return js_parse( decode_utf8_lossy($text) );
}

# Keys sorted, arrays sorted by their elements' canonical text: the reference resolves sources
# in parallel, so its warnings come in completion order.
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

sub files {
  my ( $root, %files ) = @_;
  for my $rel ( keys %files ) {
    my $p = path( $root, $rel );
    $p->parent->mkpath;
    $p->spew_raw( encode_text( $files{$rel} ) );
  }
  return "$root";
}

sub skill { "---\ndescription: $_[0]\n---\nbody\n" }

# A temp home (Claude Code in use) and project.
sub machine {
  my $tmp  = tempdir;
  my $root = $tmp->realpath;
  my $m = { tmp => $tmp, root => $root, home => "$root/home", project => "$root/project" };
  path( $m->{home}, '.claude' )->mkpath;
  path( $m->{home}, '.claude.json' )->spew_raw("{}\n");
  path( $m->{project}, '.claude' )->mkpath;
  return $m;
}

sub same_resolve {
  my ( $m, $name, %opts ) = @_;
  my $project = exists $opts{project} ? $opts{project} : $m->{project};
  my $scope   = $opts{scope} // 'all';
  my $t = ts( { op => 'resolve', home => $m->{home}, projectDir => $project, scope => $scope } );
  my $perl = eval {
    Skilletor::Resolver->new(
      home            => $m->{home},
      ( defined $project ? ( project_dir => $project ) : () ),
      codex_home      => "$m->{home}/.codex",
      require_harness => 1,
    )->resolve( scope => $scope );
  };
  my $p = defined $perl ? { result => $perl } : { error => ( ref $@ && $@->can('message') ? $@->message : "$@" ) };
  is( js_stringify( canonical($p), 2 ), js_stringify( canonical($t), 2 ), $name );
  return $p;
}

subtest 'the lock keeps offering what an unreachable source or bundle installed' => sub {
  my $m = machine();
  my $b = files( "$m->{root}/b", 'skills/x/SKILL.md' => skill('x from b'), 'skills/z/SKILL.md' => skill('z from b') );
  write_json( "$m->{home}/.claude/skilletor.json", {
    sources => { a => { local => "$m->{root}/missing" }, b => { local => $b } },
    install => { skills => [ '*@a', '*@b' ], bundles => ['z@a'] },
  } );
  write_json( "$m->{home}/.claude/skilletor.lock.json", {
    'skills/x'       => { source => 'a', version => 'local', files => {} },
    'skills/y'       => { source => 'a', version => 'local', files => {}, via => ['bundle:z@a'] },
    'skills/z'       => { source => 'c', version => 'local', files => {}, via => ['bundle:z@a'] },
    'codex:skills/x' => { source => 'a', version => 'local', files => {} },
    'weird:skills/q' => { source => 'a', version => 'local', files => {} },
  } );
  my $p = same_resolve( $m, 'kept offers collide', project => undef );
  ok( ( grep { /offered by/ } @{ $p->{result}{scopes}[0]{warnings} } ), 'a collision with a kept offer is named' );
};

subtest 'invalid names, bundle var conflicts, item errors, explicit entries' => sub {
  my $m = machine();
  my $s = files( "$m->{root}/s",
    'skills/bad name/SKILL.md' => skill('bad'),
    'skills/ok/SKILL.md'       => skill('ok'),
    'skills/shared/SKILL.md'   => skill('shared'),
    'skills/Upper/SKILL.md'    => skill('upper'),
    'agents/dup.md'            => skill('dup'),
    'agents/dup.md.njk'        => skill('dup'),
    'bundles/p.yaml'           => "description: P\nskills: [shared, ok]\nvars: {color: red, size: 1, same: x}\n",
    'bundles/q.yaml'           => "description: Q\nskills: [shared]\nvars: {color: blue, size: 2, same: x}\n",
    'skilletor.json'           => '{"vars": {"color": "source", "src": 1}}',
  );
  my $t = files( "$m->{root}/t", 'skills/ok/SKILL.md' => skill('ok from t'), 'skills/shared/SKILL.md' => skill('t') );
  write_json( "$m->{home}/.claude/skilletor.json", {
    sources => { s => { local => $s }, t => { local => $t } },
    install => {
      skills  => [ '*@s', 'ok@t', 'upper@s' ],
      agents  => ['dup@s'],
      bundles => [ 'p@s', 'bundle:q@s' ],
    },
    vars => { user => 1 },
  } );
  same_resolve( $m, 'one resolve, the same warnings and vars', project => undef );
};

subtest 'project scope: untrusted sources, served bundle entries, failed scans, paths' => sub {
  my $m = machine();
  path( $m->{root}, 'remote' )->mkpath;
  my $remote = bare_remote( $m->{root}.'/remote' );
  $remote->{commit}->( { 'skills/lint/SKILL.md' => skill('lint'), 'skills/fmt/SKILL.md' => skill('fmt') } );
  my $s = files( "$m->{root}/s",
    'skills/a/SKILL.md' => skill('a'),
    'bundles/f.yaml'    => "description: F\nskills: ['lint\@$remote->{url}', 'fmt\@$remote->{url}', 'gone\@https://example.invalid/x.git']\n",
  );
  my $bad = files( "$m->{root}/bad", 'skills/l/SKILL.md' => skill('l'), 'skills/l/target' => 'x' );
  symlink 'target', "$bad/skills/l/link" or die $!;
  my $deep = files( "$m->{root}/deep", 'tools/one/SKILL.md' => skill('one'), 'tools/x/two/SKILL.md' => skill('two') );
  write_json( "$m->{home}/.claude/skilletor.json", { sources => { s => { local => $s } }, vars => { tone => 'user' } } );
  write_json( "$m->{project}/.claude/skilletor.json", {
    sources => {
      remote => { git => $remote->{url} },
      bad    => { local => $bad },
      deep   => { local => $deep, path => 'tools' },
      nobody => { url => 'https://example.invalid/never.tar.gz' },
    },
    install => { bundles => ['f@s'], skills => [ '*@bad', '*@deep', '*@nobody' ] },
    vars    => { tone => 'project' },
    targets => ['codex'],
  } );
  write_json( "$m->{project}/.claude/skilletor.local.json", { vars => { tone => 'local' } } );
  write_json( "$m->{home}/.claude/skilletor/trust.json", { bad => { kind => 'local', address => $bad }, deep => { kind => 'local', address => $deep } } );
  same_resolve( $m, 'the reference\'s trust requests, warnings and items' );
  same_resolve( $m, 'the project scope alone', scope => 'project' );
};

subtest 'one sync lock: each engine waits for the other' => sub {
  my $root = tempdir;
  my $lock = path( $root, 'sync.lock' );
  my $state = Skilletor::State->new( root => "$root" );
  my $answer = $state->with_lock( sub { ts( { op => 'lock', root => "$root", timeoutMs => 200 } ) } );
  is_deeply( $answer, { error => 'timed out acquiring sync lock at '.$lock }, 'the port holds it: the reference times out' );
  is_deeply( ts( { op => 'lock', root => "$root", timeoutMs => 200 } ), { result => 'ran' }, 'released: the reference takes it' );

  my $pid = open2( my $out, my $in, 'node', "$runner" );
  print {$in} encode_text( js_stringify( { op => 'lock', root => "$root", timeoutMs => 5000, holdMs => 1500 } ) );
  close $in;
  my $deadline = time + 10;
  Time::HiRes::sleep(0.02) until -f $lock->child('owner.json') || time > $deadline;
  my $err;
  eval { $state->with_lock( sub { fail('ran while the reference held the lock') }, timeout_ms => 200 ); 1 } or $err = $@;
  isa_ok( $err, 'Skilletor::Error::LockTimeout', 'the reference holds it: the port times out' );
  my $ran = $state->with_lock( sub { 'ran' }, timeout_ms => 5000 );
  is( $ran, 'ran', 'and takes it once the reference let go' );
  local $/;
  my $text = <$out>;
  waitpid $pid, 0;
  is_deeply( js_parse($text), { result => 'ran' }, 'the reference ran' );
};

subtest 'errors and degenerate scopes' => sub {
  my $m = machine();
  write_json( "$m->{home}/.claude/skilletor.json", { sources => { s => { local => "$m->{root}/none" } }, install => { skills => ['x@s'] } } );
  same_resolve( $m, 'a missing local directory' );
  same_resolve( $m, 'the project dir is the home dir: no project scope', project => $m->{home} );
  path( $m->{home}, '.claude.json' )->remove;
  same_resolve( $m, 'no harness: the reference\'s error' );
  path( $m->{home}, '.claude.json' )->spew_raw("{}\n");
  path( $m->{home}, '.claude', 'skilletor.lock.json' )->spew_raw('[1]');
  same_resolve( $m, 'a lock that is no object' );
  path( $m->{home}, '.claude', 'skilletor.lock.json' )->spew_raw('{"a":');
  same_resolve( $m, 'a lock that is no JSON' );
};

done_testing;
