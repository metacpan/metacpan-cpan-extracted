package Skilletor;
# ABSTRACT: Install skills, agents and rules from remote sources – the Perl port of skilletor

use Moo;
use Carp qw( croak );
use Skilletor::Engine;
use Skilletor::Entry qw( name_key );
use Skilletor::Error::Ambiguous;
use Skilletor::Error::Unsupported;
use Skilletor::FSUtil qw( path_join );
use namespace::clean;

our $VERSION = '0.001';

has home => (
  is       => 'ro',
  required => 1,
);

has project_dir => (
  is => 'ro',
);

has fetch => (
  is      => 'ro',
  default => sub { 'always' },
);

has require_harness => (
  is      => 'ro',
  default => sub { 0 },
);

has [qw( state_root cache_root codex_home timeout_ms lock_timeout_ms is_git_work_tree git_tracked git_remote plugin_root )] => (
  is => 'ro',
);

has resolver => (
  is      => 'lazy',
  builder => sub {
    my ( $self ) = @_;
    return Skilletor::Engine->new(
      home            => $self->home,
      project_dir     => $self->project_dir,
      fetch           => $self->fetch,
      require_harness => $self->require_harness,
      map { defined $self->$_ ? ( $_ => $self->$_ ) : () }
        qw( state_root cache_root codex_home timeout_ms lock_timeout_ms is_git_work_tree git_tracked git_remote plugin_root ),
    );
  },
);

sub engine { $_[0]->resolver }

# A sync changes what the lookups would answer: the resolution they answer from goes with it.
sub sync {
  my ( $self, %opts ) = @_;
  my $report = $self->resolver->sync(%opts);
  $self->refresh;
  return $report;
}

sub check {
  my ( $self, %opts ) = @_;
  return $self->resolver->check(%opts);
}

sub status {
  my ( $self, %opts ) = @_;
  return $self->resolver->status(%opts);
}

# The resolution of every scope that resolve_* answer from, made on first use.
has _resolution => (
  is       => 'lazy',
  init_arg => undef,
  clearer  => 'refresh',
  builder  => sub { $_[0]->resolver->resolve( scope => 'all', throw => 1 ) },
);

sub resolve {
  my ( $self, %opts ) = @_;
  return $self->resolver->resolve(%opts);
}

# One resolved item as the record resolve_item returns.
sub _record {
  my ( $self, $scope, $ri ) = @_;
  my $ci    = $ri->{item};
  my $root  = $ri->{sourceDir};
  my @files = @{ $ci->{files} };
  my ( $path, $dir, $main );
  if ( $ri->{type} eq 'skill' ) {
    $path = $ci->{dir};
    $dir  = path_join( $root, $path );
    ($main) = grep { $_ eq $path.'/SKILL.md' } @files;
    $main //= $path.'/SKILL.md.njk';
  }
  else {
    $path = $main = $files[0];
    ( my $parent = $path ) =~ s{/[^/]*\z}{};
    $dir = path_join( $root, $parent eq $path ? '' : $parent );
  }
  my @templates = grep { /\.njk\z/ } @files;
  my %source = map { ( $_->{name} => $_ ) } @{ $self->_scope_report($scope)->{sources} };
  return {
    type       => $ri->{type},
    name       => $ri->{name},
    scope      => $scope,
    source     => $ri->{source},
    version    => $source{ $ri->{source} } ? $source{ $ri->{source} }{version} : undef,
    source_dir => $root,
    path       => $path,
    dir        => $dir,
    file       => path_join( $root, $main ),
    files      => [ map { path_join( $root, $_ ) } @files ],
    ( defined $ci->{description} ? ( description => $ci->{description} ) : () ),
    vars       => $ri->{vars},
    declaredBy => $ri->{declaredBy},
    ( $ri->{via} ? ( via => $ri->{via} ) : () ),
    templated  => @templates ? 1 : 0,
    templates  => \@templates,
  };
}

sub _scope_report {
  my ( $self, $scope ) = @_;
  my ($rep) = grep { $_->{scope} eq $scope } @{ $self->_resolution->{scopes} };
  return $rep;
}

# Claude Code's order per type when both scopes hold an item of one name: a personal skill wins
# over a project one, a project agent over a personal one; rules do not override each other –
# both load, the user's first.
my %ORDER = ( skill => [qw( user project )], agent => [qw( project user )], rule => [qw( user project )] );
my %SHADOWS = ( skill => 1, agent => 1, rule => 0 );
my @TYPES = qw( skill agent rule );

sub _check_type {
  my ( $type ) = @_;
  croak 'type must be skill, agent or rule' unless defined $type && $ORDER{$type};
}

sub _scopes_for {
  my ( $scope, $type ) = @_;
  $scope //= 'all';
  croak 'scope must be user, project or all' unless $scope =~ /\A(?:user|project|all)\z/;
  return $scope eq 'all' ? @{ $ORDER{$type} } : ($scope);
}

# Every record of a type, in the type's order: one per name where one scope's item wins.
sub _items_of {
  my ( $self, $type, $scope, $key ) = @_;
  my ( %seen, @out );
  for my $s ( _scopes_for( $scope, $type ) ) {
    my $rep = $self->_scope_report($s) or next;
    for my $ri ( @{ $rep->{items} } ) {
      next unless $ri->{type} eq $type;
      my $k = name_key( $ri->{name} );
      next if defined $key && $k ne $key;
      next if $SHADOWS{$type} && $seen{$k}++;
      push @out, $self->_record( $s, $ri );
    }
  }
  return @out;
}

sub items {
  my ( $self, %opts ) = @_;
  _check_type( $opts{type} ) if defined $opts{type};
  return [ map { $self->_items_of( $_, $opts{scope} ) } defined $opts{type} ? ( $opts{type} ) : @TYPES ];
}

sub resolve_items {
  my ( $self, $type, $name, %opts ) = @_;
  _check_type($type);
  return [] unless defined $name && length $name;
  my $key = name_key($name);
  my @all;
  for my $s ( _scopes_for( $opts{scope}, $type ) ) {
    push @all, grep { $_->{scope} eq $s } $self->_items_of( $type, $s, $key );
  }
  return \@all;
}

sub resolve_item {
  my ( $self, $type, $name, %opts ) = @_;
  my @found = @{ $self->resolve_items( $type, $name, %opts ) };
  return undef unless @found;
  if ( @found > 1 && !$SHADOWS{$type} ) {
    Skilletor::Error::Ambiguous->throw( $type.' '.$found[0]{name}.' is declared in the user and the project scope; '
      .'Claude Code loads both (neither overrides the other) – ask resolve_'.$type.'s, or pass a scope' );
  }
  return $found[0];
}

sub _refuse_template {
  my ( $rec ) = @_;
  return unless $rec->{templated};
  Skilletor::Error::Unsupported->throw( $rec->{type}.' '.$rec->{name}.'@'.$rec->{source}.' is a Nunjucks template ('
    .join( ', ', @{ $rec->{templates} } ).'); the Perl port of skilletor renders no templates' );
}

sub _main_file {
  my ( $self, $type, $name, %opts ) = @_;
  my $rec = $self->resolve_item( $type, $name, %opts ) or return undef;
  _refuse_template($rec);
  return $rec->{file};
}

sub resolve_skill { my $self = shift; return $self->_main_file( skill => @_ ) }
sub resolve_agent { my $self = shift; return $self->_main_file( agent => @_ ) }
sub resolve_rule  { my $self = shift; return $self->_main_file( rule  => @_ ) }

sub resolve_rules {
  my ( $self, $name, %opts ) = @_;
  my @recs = @{ $self->resolve_items( rule => $name, %opts ) };
  _refuse_template($_) for @recs;
  return map { $_->{file} } @recs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor - Install skills, agents and rules from remote sources – the Perl port of skilletor

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor;

  my $sk = Skilletor->new( home => $ENV{HOME}, project_dir => $project );

  # The skill as an include, straight from the source tree or the shared cache:
  my $file  = $sk->resolve_skill('perl-moo');   # …/cache/79eb247685294166/skills/perl-moo/SKILL.md
  my $agent = $sk->resolve_agent('reviewer');   # the project's wins over the personal one
  my @rules = $sk->resolve_rules('style');      # both scopes' rules, the user's first
  my $item  = $sk->resolve_item( skill => 'perl-moo' );
  # { type, name, scope, source, version, source_dir, path, dir, file, files,
  #   description, vars, declaredBy, via?, templated, templates }

  for my $rule ( @{ $sk->items( type => 'rule' ) } ) { ... }

  # Startup without the network: what the cache holds.
  my $offline = Skilletor->new( home => $ENV{HOME}, project_dir => $project, fetch => 'never' );

  # Install for Claude Code, as `skilletor sync` does:
  use Skilletor::Report qw( report_text exit_code );
  my $report = $sk->sync;                      # the reference's SyncReport
  print report_text($report) || 'skilletor: up to date', "\n";
  my $due = $sk->check->{changed};             # is a sync due?
  my $status = $sk->status;

  # The reference's resolveItems, field for field:
  my $resolution = $sk->resolve( scope => 'all' );

=head1 DESCRIPTION

L<skilletor|https://github.com/Getty/skilletor> installs skills, agents and
rules from remote sources (git repositories, https tarballs, local
directories) into Claude Code, Codex and Hermes, at user and project scope.
Its reference implementation is TypeScript; this distribution is its Perl
port, living in the same repository, for Perl programs – an agent such as
L<Langertha::Raider> – that must resolve skills exactly as skilletor does,
straight from the same config and the same cache, without Node, and sync them
into Claude Code's directories as the CLI does.

The port shares everything on disk with the reference: the config files
(C<~/.claude/skilletor.json>, C<< <project>/.claude/skilletor.json >>,
C<skilletor.local.json>), the source cache under C<~/.claude/skilletor/cache>
(the same directory names, so one fetch serves both), C<trust.json>, the sync
lock, the lock files and the state records C<check> reads, and the bytes
either writes. Error messages and warnings are the reference's, word for word;
the shared conformance cases (F<conformance/> in the repository) hold both to
that.

The lookups (L</resolve_skill> and its siblings, L</items>) answer "where is
skill X" the way a sync would install it, but without installing anything: an
item is served from the source tree it lies in – a C<local> directory or the
cache dir a git or url source was fetched into. L</sync>, L</check> and
L</status> are the CLI's commands for the Claude Code target
(L<Skilletor::Engine>).

=head2 Scopes and precedence

Every scope resolves on its own, as a sync installs it: the user scope from
the user config alone, the project scope from the merged project, local and
user config (spec §3). Within a scope a type and name is one item at most –
the overlap rules (explicit entries over wildcards and bundles, two sources
offering one name skip it) see to that. Across the scopes a sync installs an
item declared in both twice, once per scope; which one Claude Code then uses
depends on the type, and a lookup without a C<scope> follows Claude Code's
documented rules (names ignore case, as everywhere in skilletor):

=over 4

=item * B<Skills: the personal one wins.> "Enterprise over personal, and
personal over project": with C<deploy> in both C<~/.claude/skills/> and the
project's C<.claude/skills/>, C</deploy> runs the personal one
(code.claude.com/docs/en/skills). L</resolve_skill> answers the user's.

=item * B<Agents: the project's wins.> Claude Code takes managed, then
C<--agents>, then the project's C<.claude/agents/>, then C<~/.claude/agents/>,
then plugins (code.claude.com/docs/en/sub-agents). L</resolve_agent> answers
the project's.

=item * B<Rules: neither wins.> Claude Code loads the user's rules before the
project's, and neither set overrides the other (code.claude.com/docs/en/memory):
both are in effect. L</resolve_rules> answers both, the user's first;
L</resolve_rule> answers one only when one scope declares it – with both it
throws L<Skilletor::Error::Ambiguous> rather than hide one.

=back

Pass C<< scope => 'user' >> or C<< scope => 'project' >> to look in one scope
only; then there is never more than one.

=head2 Fetching

L</fetch> is the fetch policy: C<always> (default) resolves every source as a
sync does – a git fetch, a url download, a failure falling back to the cache
with a warning; C<missing> fetches only a source with no usable cache yet;
C<never> touches no network and serves what the cache holds, a source that was
never fetched being a warning. Every lookup method answers from one resolution
of every scope, made at the first call; L</refresh> drops it, and so does
L</sync>. The policy holds for L</sync> too: with C<never> it syncs from the
cache alone.

=head2 Templates

The Perl port renders no Nunjucks. An item with a C<.njk> file resolves like
any other – its record says C<< templated => 1 >> and lists the C<templates> –
but L</resolve_skill> and its siblings refuse it with a
L<Skilletor::Error::Unsupported>: an unrendered template is never served as if
it were the item. A L</sync> never installs one either: it warns and leaves
such an item as the reference installed it, and its scope stays open for the
reference's next sync (L<Skilletor::Engine/Templates>).

=head2 Claude Code only

L</sync>, L</check> and L</status> serve Claude Code alone. A scope that
targets Codex or Hermes – by C<"targets">, or by Codex detected on the machine
without C<"targets"> – is refused with an C<error> in the report, and a sync
is refused where the reference left Codex or Hermes state behind; nothing is
written then (L<Skilletor::Engine/Claude Code only>). Unlike the lookups, they
need an agent harness, as the reference does.

=head2 Modules

=over 4

=item * L<Skilletor::Resolver> – the resolve (the reference's C<resolveItems>);
L<Skilletor::Engine> – sync, check, status on top of it.

=item * L<Skilletor::Config> – load, merge and validate the three config files; edit them.

=item * L<Skilletor::Catalog>, L<Skilletor::Bundles>, L<Skilletor::Frontmatter> –
source trees, bundle files and their YAML subset.

=item * L<Skilletor::Entry> – install entries, patterns and bundle entries.

=item * L<Skilletor::Spec> – resolve an C<add> shorthand to a source.

=item * L<Skilletor::Backend> – choose a source's backend (author mode) and build it.

=item * L<Skilletor::Source::Local>, L<Skilletor::Source::Git>, L<Skilletor::Source::Url>
– the backends (L<Skilletor::Role::Source>), with L<Skilletor::Cache>,
L<Skilletor::Tar> and L<Skilletor::Gzip>.

=item * L<Skilletor::Render> – an item's files in memory; L<Skilletor::Apply> – onto
the disk, against the lock; L<Skilletor::Lock> – lock files.

=item * L<Skilletor::Gitignore>, L<Skilletor::ClaudeSettings>, L<Skilletor::Briefing>
– the managed blocks, the project's plugin requirement, the briefing check.

=item * L<Skilletor::State> – trust, the sync lock and the records C<check> reads.

=item * L<Skilletor::Targets> – harness detection, the targets merge, the layout table.

=item * L<Skilletor::Report> – the reports' text and exit codes, as the CLI words them.

=item * L<Skilletor::JSON>, L<Skilletor::JSString>, L<Skilletor::URL>,
L<Skilletor::FSUtil>, L<Skilletor::GitEnv>, L<Skilletor::Process> – JavaScript and
Node behaviour where it reaches a byte, a name or a message.

=back

=head1 CONVENTIONS

Data structures carry the reference's field names (C<derivedName>,
C<declaredBy>, C<trustRequests>) so they compare with the TypeScript side
directly; methods are snake_case. Paths are character strings, as the
reference's are; Perl hands their UTF-8 bytes to the file system. A home
directory is always passed in – nothing reads C<$ENV{HOME}> on its own.

=head2 home

Required: the home whose C<.claude/skilletor.json> and cache are used.

=head2 project_dir

The project; none (or the home dir itself) means the user scope alone.

=head2 fetch

C<always> (default), C<missing> or C<never>; see L</Fetching>.

=head2 require_harness

True: the lookups fail as the reference does when no agent harness (Claude
Code, Codex) is detected and the user config names no C<targets>. Default
false: resolving needs no harness. L</sync>, L</check> and L</status> always
need one.

=head2 state_root

=head2 cache_root

=head2 codex_home

=head2 timeout_ms

=head2 lock_timeout_ms

Passed to L<Skilletor::Resolver>; its defaults without them.

=head2 is_git_work_tree

=head2 git_tracked

=head2 git_remote

=head2 plugin_root

Passed to L<Skilletor::Engine>, where they are described; the questions to git
and the plugin root they answer default to git and C<CLAUDE_PLUGIN_ROOT>.

=head2 resolver

The L<Skilletor::Engine> (a L<Skilletor::Resolver>) doing the work.

=head2 engine

The same as L</resolver>.

=head2 resolve

  my $report = $sk->resolve( scope => 'user' | 'project' | 'all' );

A fresh resolve, the reference's C<ResolveReport> (see L<Skilletor::Resolver>):
C<< { scopes => [ { scope, items, sources, warnings, trustRequests } ] } >>, or
C<< { scopes => [], error => $message } >> on a config error.

=head2 resolve_item

  my $rec = $sk->resolve_item( skill => 'perl-moo', scope => 'all' );

The record of the item a lookup finds by the type's precedence
(L</Scopes and precedence>), or undef for a name no scope resolves to (also
when the item was declared but its source or the item itself could not be
read – the warning in L</resolve> says why):

  {
    type => 'skill', name => 'perl-moo', scope => 'project',
    source => 'shared', version => 'git:30993b3',
    source_dir => '/home/me/.claude/skilletor/cache/b966aec947fa313b',
    path  => 'skills/perl-moo',                  # relative to source_dir, as in the report
    dir   => '…/skills/perl-moo',                # a skill's directory; an agent's or rule's parent
    file  => '…/skills/perl-moo/SKILL.md',       # the main file
    files => [ '…/skills/perl-moo/SKILL.md', … ],
    description => 'Write Moo classes',          # when the frontmatter has one
    vars => { … }, declaredBy => [ … ], via => [ … ],
    templated => 0, templates => [],             # the .njk files, relative
  }

A rule both scopes declare throws L<Skilletor::Error::Ambiguous> unless a
C<scope> is given. A config error throws L<Skilletor::Error::Config>; an
unreadable lock file and a sync lock held too long throw too.

=head2 resolve_items

  my $recs = $sk->resolve_items( rule => 'style' );

Every record of the type and name, one per scope that declares it, in the
type's order: skills user then project, agents project then user, rules user
then project. The first is the one Claude Code uses for a skill or an agent;
for rules all are in effect.

=head2 resolve_skill

  my $file = $sk->resolve_skill( 'perl-moo', scope => 'all' );

The absolute path of the skill's C<SKILL.md> in its source tree, or undef;
with both scopes declaring the skill, the user's. Throws
L<Skilletor::Error::Unsupported> for a templated skill.

=head2 resolve_agent

The agent's C<< <name>.md >>, as L</resolve_skill>; with both scopes declaring
the agent, the project's.

=head2 resolve_rule

The rule's C<< <name>.md >>, as L</resolve_skill> – when one scope declares
it. With both, Claude Code loads both: this throws
L<Skilletor::Error::Ambiguous>; ask L</resolve_rules>, or pass a C<scope>.

=head2 resolve_rules

  my @files = $sk->resolve_rules( 'style', scope => 'all' );

The C<< <name>.md >> of every scope's rule of the name, the user's first; none
when no scope declares it. Throws L<Skilletor::Error::Unsupported> when one of
them is templated.

=head2 items

  my $records = $sk->items( type => 'skill', scope => 'all' );

Every item record (L</resolve_item>), skills first, then agents, then rules,
each type in its order: one skill per name (the user's winning), one agent per
name (the project's winning), and every rule of every scope. C<type> and
C<scope> are optional filters.

=head2 sync

  my $report = $sk->sync( scope => 'all', force => 0 );

Install what the config declares for Claude Code, as C<skilletor sync> does,
and drop the resolution the lookups answer from. The reference's
C<SyncReport> (L<Skilletor::Engine/sync>); a config error, no agent harness, a
scope targeting another harness are its C<error>, with nothing touched. Throws
when a write fails midway (the lock then owns what landed, marked
C<partial>). L<Skilletor::Report> words it.

=head2 check

  my $check = $sk->check( scope => 'all' );
  print "a sync is due\n" if $check->{changed};

The reference's C<CheckReport> (L<Skilletor::Engine/check>): whether a sync
is due, without one.

=head2 status

  my $status = $sk->status( scope => 'all' );

The reference's C<StatusReport> (L<Skilletor::Engine/status>), offline.

=head2 refresh

Drop the resolution the lookup methods answer from; the next call resolves
again (and fetches, by L</fetch>).

=head1 SEE ALSO

L<https://github.com/Getty/skilletor> – the reference implementation and its
design spec, F<docs/superpowers/specs/2026-09-22-skilletor-design.md>.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
