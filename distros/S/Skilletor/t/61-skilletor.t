#!/usr/bin/env perl
# The Perl API around the resolve: item lookups, the scope rule, templates, fetch policies, and
# resolving on a machine without an agent harness.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of write_json bare_remote );

use Path::Tiny qw( path tempdir );
use Skilletor;
use Skilletor::FSUtil qw( encode_text );

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

my $tmp  = tempdir;
my $root = $tmp->realpath;
my $home = "$root/home";
my $proj = "$root/project";
path( $home, '.claude' )->mkpath;    # no .claude.json: no harness detected
path( $proj, '.claude' )->mkpath;

my $user_src = files( "$root/user-src",
  'skills/perl-moo/SKILL.md'  => skill('user moo'),
  'skills/perl-moo/notes.md'  => "n\n",
  'skills/only-user/SKILL.md' => skill('only user'),
  'skills/tmpl/SKILL.md'      => skill('plain main'),
  'skills/tmpl/extra.md.njk'  => "{{ x }}\n",
  'agents/reviewer.md'        => skill('user reviewer'),
  'rules/style.md'            => skill('user style'),
  'skilletor.json'            => '{"vars": {"level": "source"}}',
);
my $proj_src = files( "$root/proj-src",
  'skills/Perl-Moo/SKILL.md' => skill('project moo'),
  'agents/helper.md.njk'     => skill('{{ vars.x }}'),
  'agents/reviewer.md'       => skill('project reviewer'),
  'rules/style.md'           => skill('project style'),
);
write_json( "$home/.claude/skilletor.json", {
  sources => { u => { local => $user_src } },
  install => { skills => [ 'perl-moo@u', 'only-user@u', 'tmpl@u' ], agents => ['*@u'], rules => ['style@u'] },
  vars    => { level => 'user' },
} );
write_json( "$proj/.claude/skilletor.local.json", {
  sources => { p => { local => $proj_src } },
  install => { skills => ['Perl-Moo@p'], agents => [ 'helper@p', 'reviewer@p' ], rules => ['style@p'] },
  vars    => { level => 'local' },
} );

my $sk = Skilletor->new( home => $home, project_dir => $proj );

subtest 'resolve needs no agent harness here' => sub {
  my $r = $sk->resolve;
  ok( !exists $r->{error}, 'no error without .claude.json' ) or diag $r->{error};
  is_deeply( [ map { $_->{scope} } @{ $r->{scopes} } ], [qw( user project )], 'both scopes' );
  my $strict = Skilletor->new( home => $home, project_dir => $proj, require_harness => 1 )->resolve;
  like( $strict->{error}, qr/\Ano agent harness detected/, 'require_harness: the reference\'s error' );
  is_deeply( $strict->{scopes}, [], 'and nothing resolved' );
};

subtest 'resolve_skill and co: the main file in the source tree, by Claude Code\'s precedence' => sub {
  is( $sk->resolve_skill('perl-moo'), "$user_src/skills/perl-moo/SKILL.md", 'a skill: the personal one wins over the project\'s' );
  is( $sk->resolve_skill('PERL-MOO'), "$user_src/skills/perl-moo/SKILL.md", 'names ignore case' );
  is( $sk->resolve_skill( 'perl-moo', scope => 'user' ), "$user_src/skills/perl-moo/SKILL.md", 'scope => user' );
  is( $sk->resolve_skill( 'PERL-MOO', scope => 'project' ), "$proj_src/skills/Perl-Moo/SKILL.md", 'scope => project' );
  is( $sk->resolve_skill('only-user'), "$user_src/skills/only-user/SKILL.md", 'a user item the project lacks' );
  is( $sk->resolve_skill( 'only-user', scope => 'project' ), undef, 'not declared in the project scope' );
  is( $sk->resolve_skill('nope'), undef, 'unknown: undef' );
  is( $sk->resolve_skill(''), undef, 'empty: undef' );
  is( $sk->resolve_agent('reviewer'), "$proj_src/agents/reviewer.md", 'an agent: the project\'s wins over the personal one' );
  is( $sk->resolve_agent( 'reviewer', scope => 'user' ), "$user_src/agents/reviewer.md", 'scope => user: the one a wildcard declares' );
  is( $sk->resolve_skill('reviewer'), undef, 'types do not mix' );
};

subtest 'rules: both scopes load, neither shadows the other' => sub {
  is_deeply( [ $sk->resolve_rules('style') ], [ "$user_src/rules/style.md", "$proj_src/rules/style.md" ], 'resolve_rules: the user\'s first' );
  is_deeply( [ $sk->resolve_rules( 'style', scope => 'project' ) ], ["$proj_src/rules/style.md"], 'one scope' );
  is_deeply( [ $sk->resolve_rules('nope') ], [], 'unknown: none' );
  my $err;
  eval { $sk->resolve_rule('style'); 1 } or $err = $@;
  isa_ok( $err, 'Skilletor::Error::Ambiguous', 'resolve_rule of a rule both scopes declare' );
  like( $err->message, qr/\Arule style is declared in the user and the project scope; Claude Code loads both/, 'the message' );
  my $item_err;
  eval { $sk->resolve_item( rule => 'style' ); 1 } or $item_err = $@;
  isa_ok( $item_err, 'Skilletor::Error::Ambiguous', 'resolve_item too' );
  is( $sk->resolve_rule( 'style', scope => 'user' ), "$user_src/rules/style.md", 'a scope narrows it: the user\'s' );
  is( $sk->resolve_rule( 'style', scope => 'project' ), "$proj_src/rules/style.md", 'and the project\'s' );
  is_deeply( [ map { "$_->{scope}:$_->{name}" } @{ $sk->resolve_items( rule => 'STYLE' ) } ], [ 'user:style', 'project:style' ],
    'resolve_items: every record, in load order' );
  is_deeply( [ map { "$_->{scope}:$_->{name}" } @{ $sk->items( type => 'rule' ) } ], [ 'user:style', 'project:style' ],
    'items: both rules' );
};

subtest 'resolve_item: the record' => sub {
  my $rec = $sk->resolve_item( skill => 'perl-moo', scope => 'user' );
  is_deeply(
    $rec,
    {
      type        => 'skill',
      name        => 'perl-moo',
      scope       => 'user',
      source      => 'u',
      version     => 'local',
      source_dir  => $user_src,
      path        => 'skills/perl-moo',
      dir         => "$user_src/skills/perl-moo",
      file        => "$user_src/skills/perl-moo/SKILL.md",
      files       => [ "$user_src/skills/perl-moo/SKILL.md", "$user_src/skills/perl-moo/notes.md" ],
      description => 'user moo',
      vars        => { level => 'user' },
      declaredBy  => ['perl-moo@u'],
      templated   => 0,
      templates   => [],
    },
    'a skill',
  );
  my $agent = $sk->resolve_item( agent => 'reviewer', scope => 'user' );
  is( $agent->{dir}, "$user_src/agents", 'an agent\'s dir: the one holding its file' );
  is_deeply( $agent->{declaredBy}, ['*@u'], 'declared by the wildcard' );
  is( $sk->resolve_item( rule => 'style', scope => 'project' )->{vars}{level}, 'local', 'project items: local vars win' );
  is_deeply( [ map { "$_->{scope}:$_->{name}" } @{ $sk->items( type => 'skill' ) } ],
    [ 'user:perl-moo', 'user:only-user', 'user:tmpl' ], 'items: one skill per name, the user\'s winning' );
  is_deeply( [ map { "$_->{scope}:$_->{name}" } @{ $sk->items( type => 'agent' ) } ],
    [ 'project:helper', 'project:reviewer' ], 'one agent per name, the project\'s winning' );
  is_deeply( [ map { "$_->{type}:$_->{scope}" } @{ $sk->items } ],
    [ 'skill:user', 'skill:user', 'skill:user', 'agent:project', 'agent:project', 'rule:user', 'rule:project' ],
    'every type: skills, agents, rules' );
  is( scalar @{ $sk->items( scope => 'user' ) }, 5, 'items of one scope' );
  like( error_of( sub { $sk->resolve_item( widget => 'x' ) } ), qr/type must be skill, agent or rule/, 'a type is checked' );
};

subtest 'templates are flagged, and refused as includes' => sub {
  my $rec = $sk->resolve_item( skill => 'tmpl' );
  is( $rec->{templated}, 1, 'a companion .njk makes the skill templated' );
  is_deeply( $rec->{templates}, ['skills/tmpl/extra.md.njk'], 'which files' );
  my $err;
  eval { $sk->resolve_skill('tmpl'); 1 } or $err = $@;
  isa_ok( $err, 'Skilletor::Error::Unsupported' );
  like( $err->message, qr/\Askill tmpl\@u is a Nunjucks template \(skills\/tmpl\/extra\.md\.njk\); the Perl port/, 'the message' );
  my $agent = $sk->resolve_item( agent => 'helper' );
  is( $agent->{file}, "$proj_src/agents/helper.md.njk", 'a templated main file is still located' );
  like( error_of( sub { $sk->resolve_agent('helper') } ), qr/agent helper\@p is a Nunjucks template/, 'and refused' );
};

subtest 'the resolution is made once; refresh drops it' => sub {
  my $s = Skilletor->new( home => $home, project_dir => $proj );
  is( $s->resolve_skill('only-user'), "$user_src/skills/only-user/SKILL.md", 'resolved' );
  write_json( "$home/.claude/skilletor.json", { sources => { u => { local => $user_src } }, install => {} } );
  is( $s->resolve_skill('only-user'), "$user_src/skills/only-user/SKILL.md", 'answered from the first resolution' );
  $s->refresh;
  is( $s->resolve_skill( 'only-user', scope => 'user' ), undef, 'refresh: resolved again' );
  path( $home, '.claude', 'skilletor.json' )->spew_raw('{');
  $s->refresh;
  my $err;
  eval { $s->resolve_skill('x'); 1 } or $err = $@;
  isa_ok( $err, 'Skilletor::Error::Config', 'a config error throws from a lookup' );
  like( $sk->resolve( scope => 'user' )->{error}, qr/skilletor\.json: invalid JSON/, 'and is the report\'s error in resolve' );
};

subtest 'fetch policies on a git source' => sub {
  my $h = "$root/fetch-home";
  path( $h, '.claude' )->mkpath;
  path( "$root/remote" )->mkpath;
  my $remote = bare_remote("$root/remote");
  $remote->{commit}->( { 'skills/lint/SKILL.md' => skill('v1') } );
  write_json( "$h/.claude/skilletor.json", { sources => { r => { git => $remote->{url} } }, install => { skills => ['lint@r'] } } );
  my $make = sub { Skilletor->new( home => $h, fetch => $_[0] ) };

  my $never = $make->('never')->resolve;
  is_deeply( $never->{scopes}[0]{warnings}, [ 'source r: git source '.$remote->{url}.' is not in the cache (no fetch)' ], 'never, no cache: a warning' );
  is( $never->{scopes}[0]{sources}[0]{state}, 'failed', 'the source failed' );
  is( $make->('never')->resolve_skill('lint'), undef, 'and the item is not there' );

  my $first = $make->('missing')->resolve_item( skill => 'lint' );
  ok( $first && -f $first->{file}, 'missing, no cache: fetched' );
  $remote->{commit}->( { 'skills/lint/SKILL.md' => skill('v2') } );
  is( $make->('missing')->resolve_item( skill => 'lint' )->{description}, 'v1', 'missing, cached: no fetch' );
  is( $make->('never')->resolve_item( skill => 'lint' )->{version}, $first->{version}, 'never, cached: the cache' );
  is( $make->('always')->resolve_item( skill => 'lint' )->{description}, 'v2', 'always: fetched' );
  is( $make->('never')->resolve_item( skill => 'lint' )->{description}, 'v2', 'never: what always fetched' );
  $remote->{gone}->();
  my $offline = $make->('always')->resolve;
  like( $offline->{scopes}[0]{warnings}[0], qr/\Agit fetch failed for \Q$remote->{url}\E, using cache/, 'always, remote gone: the reference\'s fallback warning' );
  is_deeply( $make->('never')->resolve->{scopes}[0]{warnings}, [], 'never: no warning, the cache serves' );
  like( error_of( sub { Skilletor::Resolver->new( home => $h, fetch => 'sometimes' ) } ), qr/fetch must be always, missing or never/, 'the policy is checked' );
};

subtest 'fetch never on a url source' => sub {
  my $h = "$root/url-home";
  path( $h, '.claude' )->mkpath;
  write_json( "$h/.claude/skilletor.json", { sources => { t => { url => 'https://example.invalid/t.tar.gz' } }, install => { skills => ['x@t'] } } );
  is_deeply( Skilletor->new( home => $h, fetch => 'never' )->resolve->{scopes}[0]{warnings},
    ['source t: url source https://example.invalid/t.tar.gz is not in the cache (no fetch)'], 'no cache, no request' );
};

done_testing;
