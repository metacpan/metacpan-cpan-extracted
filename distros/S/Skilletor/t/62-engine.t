#!/usr/bin/env perl
# What the shared cases cannot show: the port's own rules for sync – an installed template stays
# as the reference left it and keeps the scope open for the reference; a scope of another
# harness, or one the reference left Codex state in, is refused before anything is written – a
# sync that fails midway (partial entries, records cleared), the facade, and the report text.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json );

use Path::Tiny qw( path tempdir );
use Skilletor;
use Skilletor::Apply qw( apply );
use Skilletor::Engine;
use Skilletor::FSUtil qw( encode_text hash_bytes );
use Skilletor::JSON qw( js_parse );
use Skilletor::Lock qw( read_lock );
use Skilletor::Report qw( check_text display_safe exit_code report_text status_text );
use Skilletor::State;

sub files {
  my ( $root, %files ) = @_;
  for my $rel ( keys %files ) {
    my $p = path( $root, $rel );
    $p->parent->mkpath;
    $p->spew_raw( encode_text( $files{$rel} ) );
  }
  return "$root";
}

sub skill { "---\ndescription: $_[0]\n---\nbody of $_[0]\n" }

# A temp home with Claude Code in use, and a local source.
sub machine {
  my ( %src ) = @_;
  my $root = tempdir->realpath;
  my $m = { root => $root, home => "$root/home", project => "$root/project" };
  path( $m->{home}, '.claude' )->mkpath;
  path( $m->{home}, '.claude.json' )->spew_raw("{}\n");
  path( $m->{project}, '.claude' )->mkpath;
  $m->{src} = files( "$root/src", %src );
  $m->{engine} = sub {
    Skilletor::Engine->new( home => $m->{home}, project_dir => $m->{project}, codex_home => "$m->{home}/.codex",
      is_git_work_tree => sub { 0 }, git_tracked => sub { [] }, @_ );
  };
  return $m;
}

sub state_json {
  my ( $m, $name ) = @_;
  my $f = "$m->{home}/.claude/skilletor/$name";
  return -f $f ? js_parse( path($f)->slurp_utf8 ) : {};
}

subtest 'a template stays as installed, and its scope stays open' => sub {
  my $m = machine( 'skills/greet/SKILL.md.njk' => skill('hello {{ vars.who }}'), 'skills/plain/SKILL.md' => skill('plain') );
  write_json( "$m->{home}/.claude/skilletor.json",
    { sources => { s => { local => $m->{src} } }, install => { skills => [ 'greet@s', 'plain@s' ] }, vars => { who => 'me' } } );
  # What a reference sync installed of the template.
  my $rendered = skill('hello me');
  files( "$m->{home}/.claude", 'skills/greet/SKILL.md' => $rendered );
  my $lock = { 'skills/greet' => { source => 's', version => 'local', files => { 'skills/greet/SKILL.md' => hash_bytes( encode_text($rendered) ) } } };
  write_json( "$m->{home}/.claude/skilletor.lock.json", $lock );
  my $before_lock = path( $m->{home}, '.claude', 'skilletor.lock.json' )->slurp_raw;

  my $r = $m->{engine}->()->sync( scope => 'user' );
  my $s = $r->{scopes}[0];
  is_deeply( [ map { $_->{key} } @{ $s->{added} } ], ['skills/plain'], 'the plain skill is installed' );
  is_deeply( [ map { $_->{key} } @{ $s->{removed} }, @{ $s->{updated} } ], [], 'the template is neither removed nor updated' );
  is_deeply( $s->{warnings}, [ 'skill greet@s is a Nunjucks template (skills/greet/SKILL.md.njk) the Perl port of skilletor does not render; an installed copy stays' ],
    'one warning names it' );
  is( path( $m->{home}, '.claude', 'skills', 'greet', 'SKILL.md' )->slurp_utf8, $rendered, 'its installed copy is untouched' );
  my $after = read_lock("$m->{home}/.claude/skilletor.lock.json");
  is_deeply( $after->{'skills/greet'}, js_parse($before_lock)->{'skills/greet'}, 'and its lock entry' );
  ok( !-e "$m->{home}/.claude/skills/greet/.gitignore", 'nothing of skilletor\'s added to it' );

  my $lock_path = "$m->{home}/.claude/skilletor.lock.json";
  ok( !exists state_json( $m, 'render-inputs.json' )->{$lock_path}, 'what it rendered with is not recorded' );
  ok( !exists state_json( $m, 'sources-read.json' )->{$lock_path}, 'nor what it read of the source' );
  my $check = $m->{engine}->()->check( scope => 'user' );
  ok( $check->{changed}, 'check still asks for a sync – one the reference can complete' );
  is_deeply( $check->{varsChanged}, ['user'], 'the render inputs count' );
};


subtest 'a template never installed is not installed unrendered' => sub {
  my $m = machine( 'agents/helper.md.njk' => skill('{{ vars.x }}') );
  write_json( "$m->{home}/.claude/skilletor.json", { sources => { s => { local => $m->{src} } }, install => { agents => ['helper@s'] } } );
  my $r = $m->{engine}->()->sync( scope => 'user' );
  like( $r->{scopes}[0]{warnings}[0], qr/\Aagent helper\@s is a Nunjucks template/, 'warned' );
  ok( !-e "$m->{home}/.claude/agents", 'nothing written' );
  ok( !-e "$m->{home}/.claude/skilletor.lock.json", 'no lock' );
  is( $m->{engine}->()->status( scope => 'user' )->{scopes}[0]{declared}[0]{installed}, JSON::MaybeXS::false(), 'status: not installed' );
};

subtest 'another harness: refused before anything is written' => sub {
  my $m = machine( 'skills/a/SKILL.md' => skill('a') );
  write_json( "$m->{home}/.claude/skilletor.json",
    { sources => { s => { local => $m->{src} } }, install => { skills => ['a@s'] }, targets => [ 'claude', 'codex' ] } );
  my $e = $m->{engine}->();
  my $want = 'the user scope targets codex; the Perl port of skilletor installs for Claude Code only (set "targets": ["claude"] in ~/.claude/skilletor.json, or use the skilletor CLI)';
  is_deeply( $e->sync, { scopes => [], error => $want }, 'sync: an error' );
  ok( !-e "$m->{home}/.claude/skills", 'nothing installed' );
  ok( !-e "$m->{home}/.agents", 'nothing for Codex either' );
  is( $e->check->{error}, $want, 'check refuses too' );
  is( $e->status->{error}, $want, 'and status' );

  write_json( "$m->{home}/.claude/skilletor.json", { sources => { s => { local => $m->{src} } }, install => { skills => ['a@s'] }, targets => ['claude'] } );
  write_json( "$m->{project}/.claude/skilletor.json", { targets => ['codex'] } );
  my $r = $e->sync;
  is( $r->{error}, undef, 'a project narrowed to a harness not in use is no error' );
  like( $r->{scopes}[1]{warnings}[0], qr/\Aproject targets \(codex\) are not in use on this machine/, 'the reference\'s warning' );
};

subtest 'Codex state the reference left: refused, untouched' => sub {
  my $m = machine( 'skills/a/SKILL.md' => skill('a') );
  write_json( "$m->{home}/.claude/skilletor.json", { sources => { s => { local => $m->{src} } }, install => { skills => ['a@s'] } } );
  files( "$m->{home}/.agents", 'skills/a/SKILL.md' => skill('a') );
  write_json( "$m->{home}/.claude/skilletor.lock.json",
    { 'codex:skills/a' => { source => 's', version => 'local', files => { 'skills/a/SKILL.md' => hash_bytes( encode_text( skill('a') ) ) } } } );
  my $r = $m->{engine}->()->sync;
  like( $r->{error}, qr{\Q$m->{home}\E/\.claude/skilletor\.lock\.json holds items of another harness \(codex:skills/a\); the Perl port}, 'a lock with Codex entries' );
  ok( -e "$m->{home}/.agents/skills/a/SKILL.md", 'the Codex copy stays' );
  ok( !-e "$m->{home}/.claude/skills/a", 'and nothing was installed' );
  my $status = $m->{engine}->()->status( scope => 'user' );
  is_deeply( $status->{scopes}[0]{orphans}, ['codex:skills/a'], 'status reads it: an entry of an inactive target' );
  ok( $m->{engine}->()->check( scope => 'user' )->{targetsChanged}, 'check: target drift, as the reference says' );

  path( $m->{home}, '.claude', 'skilletor.lock.json' )->remove;
  files( "$m->{home}/.codex", 'skilletor-rules.md' => "# rules\n" );
  like( $m->{engine}->()->sync->{error}, qr{\Q$m->{home}\E/\.codex/skilletor-rules\.md exists; the Perl port}, 'a Codex rules file' );

  path( $m->{home}, '.codex', 'skilletor-rules.md' )->remove;
  write_json( "$m->{home}/.claude/skilletor.lock.json", { 'future:skills/x' => { source => 's', version => 'local', files => {} } } );
  my $ok = $m->{engine}->()->sync( scope => 'user' );
  is( $ok->{error}, undef, 'an entry of an unknown harness is no refusal' );
  ok( exists read_lock("$m->{home}/.claude/skilletor.lock.json")->{'future:skills/x'}, 'it is kept untouched' );
};

subtest 'no agent harness: the reference\'s error, nothing touched' => sub {
  my $m = machine( 'skills/a/SKILL.md' => skill('a') );
  path( $m->{home}, '.claude.json' )->remove;
  write_json( "$m->{home}/.claude/skilletor.json", { sources => { s => { local => $m->{src} } }, install => { skills => ['a@s'] } } );
  like( $m->{engine}->()->sync->{error}, qr/\Ano agent harness detected \(looked for claude: /, 'sync' );
  ok( !-e "$m->{home}/.claude/skills", 'nothing installed' );
};

subtest 'apply: a run that throws leaves a lock owning what landed, marked partial' => sub {
  my $dir = tempdir->realpath;
  my $item = sub { { key => "skills/$_[0]", type => 'skill', name => $_[0], source => 's', version => 'v', output => [ [ "skills/$_[0]/SKILL.md", "x\n" ] ] } };
  my $err;
  eval { apply( [ $item->('good'), $item->('bad name') ], target_dir => "$dir" ); 1 } or $err = $@;
  isa_ok( $err, 'Skilletor::Error::Apply' );
  is( $err->message, 'invalid item name: bad name', 'the reference\'s message' );
  my $lock = read_lock("$dir/skilletor.lock.json");
  is_deeply( [ keys %$lock ], ['skills/good'], 'the lock owns the item that landed' );
  ok( $lock->{'skills/good'}{partial}, 'marked partial' );
};

SKIP: {
  skip 'root writes into a read-only directory', 1 unless $> != 0;
  subtest 'sync: a write that fails midway' => sub {
    my $m = machine( 'skills/a/SKILL.md' => skill('a'), 'skills/b/SKILL.md' => skill('b') );
    write_json( "$m->{home}/.claude/skilletor.json", { sources => { s => { local => $m->{src} } }, install => { skills => [ 'a@s', 'b@s' ] } } );
    my $blocked = path( $m->{home}, '.claude', 'skills', 'b' );
    $blocked->mkpath;
    chmod 0555, "$blocked";
    my $lock_path = "$m->{home}/.claude/skilletor.lock.json";
    my $state = Skilletor::State->new( root => "$m->{home}/.claude/skilletor" );
    $state->put_render_inputs( $lock_path, 'sha256:earlier' );
    my $err;
    eval { $m->{engine}->()->sync( scope => 'user' ); 1 } or $err = $@;
    ok( $err, 'the sync throws' ) or return;
    my $lock = read_lock($lock_path);
    ok( $lock->{'skills/a'}{partial}, 'what landed is owned, partial' );
    ok( !$lock->{'skills/b'}, 'what did not land is not' );
    is( $state->render_inputs($lock_path), undef, 'the scope\'s records are cleared' );
    my $check = $m->{engine}->()->check( scope => 'user' );
    is_deeply( $check->{declaredChanged}, ['user'], 'check asks for the retry' );
    ok( $m->{engine}->()->status( scope => 'user' )->{scopes}[0]{declared}[0]{partial}, 'status: partial' );
    chmod 0755, "$blocked";
    my $r = $m->{engine}->()->sync( scope => 'user' );
    is_deeply( [ map { $_->{key} } @{ $r->{scopes}[0]{updated} } ], ['skills/a'], 'the retry completes the partial item (updated)' );
    is_deeply( [ map { $_->{key} } @{ $r->{scopes}[0]{added} } ], ['skills/b'], 'and installs the other' );
    ok( !read_lock($lock_path)->{'skills/a'}{partial}, 'the marker goes' );
  };
}

subtest 'the facade: sync, check, status, and the lookups after a sync' => sub {
  my $m = machine( 'skills/a/SKILL.md' => skill('a'), 'agents/r.md' => skill('r') );
  write_json( "$m->{home}/.claude/skilletor.json", { sources => { s => { local => $m->{src} } }, install => { skills => ['a@s'] } } );
  my $sk = Skilletor->new( home => $m->{home}, codex_home => "$m->{home}/.codex", is_git_work_tree => sub { 0 } );
  is( $sk->resolve_agent('r'), undef, 'not declared yet' );
  my $r = $sk->sync;
  is( exit_code( sync => $r ), 0, 'exit 0' );
  is( report_text($r), "skilletor: user scope\n  + skills/a (active now)", 'the CLI\'s text' );
  write_json( "$m->{home}/.claude/skilletor.json", { sources => { s => { local => $m->{src} } }, install => { skills => ['a@s'], agents => ['r@s'] } } );
  is( exit_code( check => $sk->check ), 1, 'check: a sync is due (exit 1)' );
  is( check_text( $sk->check ), 'changed', 'check text' );
  $r = $sk->sync;
  is( report_text($r), "skilletor: user scope\n  + agents/r (active after /reload-plugins or restart)", 'an agent\'s hint' );
  is( $sk->resolve_agent('r'), "$m->{src}/agents/r.md", 'a sync drops the resolution the lookups answer from' );
  is( report_text( $sk->sync ), '', 'nothing to say: empty (the CLI prints "up to date")' );
  is( status_text( $sk->status ), "user scope:\n  ✓ skills/a \@s\n  ✓ agents/r \@s", 'the status text' );
  my $bad = Skilletor->new( home => "$m->{root}/nowhere" );
  is( exit_code( status => $bad->status ), 2, 'an error: exit 2' );
};

subtest 'display_safe' => sub {
  my $want = join '', 'a', "\\", 'nb', "\t", 'c', "\\", 'u001b[31m', "\\", 'u202ed', "\x{200d}";
  is( display_safe("a\nb\tc\x{1b}[31m\x{202e}d\x{200d}"), $want, 'controls and bidi escaped; tab and ZWJ stay' );
};

done_testing;
