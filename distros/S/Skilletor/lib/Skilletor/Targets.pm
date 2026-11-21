package Skilletor::Targets;
# ABSTRACT: Which agent harnesses a sync installs for (detection and the targets merge)

use strict;
use warnings;

use Exporter qw( import );
use Skilletor::Entry qw( HARNESSES );
use Skilletor::Error::Target;
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text path_join read_text );
use Skilletor::Gitignore qw( SKILL_GITIGNORE );
use Skilletor::JSON qw( js_parse js_type );
use Skilletor::JSString qw( js_trim );
use Skilletor::Lock qw( parse_lock_key );

our $VERSION = '0.008000';

our @EXPORT_OK = qw(
  DETECTED default_markers detect_harnesses detect_project_harnesses select_targets default_hermes_home
  lock_key supports root_of root_of_key served_via receivers is_block_type is_local_type all_roots target_gaps
  place_output lacks_local_prefix
);

# Only Claude and Codex are detected; Hermes is a target only when `targets` names it.
use constant DETECTED => qw( claude codex );

# $claude_config_dir: an explicit CLAUDE_CONFIG_DIR, inside which Claude Code keeps its .claude.json.
sub default_markers {
  my ( $home, $codex_home, $claude_config_dir ) = @_;
  my $cx = ( defined $codex_home && length $codex_home ) ? $codex_home : path_join( $home, '.codex' );
  return {
    claude => ( defined $claude_config_dir && length $claude_config_dir )
      ? [ map { path_join( $claude_config_dir, $_ ) } qw( .claude.json settings.json projects ) ]
      : [ path_join( $home, '.claude.json' ), path_join( $home, '.claude', 'settings.json' ), path_join( $home, '.claude', 'projects' ) ],
    codex  => [ map { path_join( $cx, $_ ) } qw( config.toml auth.json sessions installation_id ) ],
  };
}

sub detect_harnesses {
  my ( $markers ) = @_;
  return [ grep { my $h = $_; grep { -e $_ } @{ $markers->{$h} // [] } } DETECTED ];
}

sub _path_is_evidence {
  my ( $path ) = @_;
  return lstat( encode_text($path) ) ? 1 : 0;
}

sub _path_is_link {
  my ( $path ) = @_;
  return lstat( encode_text($path) ) && -l _ ? 1 : 0;
}

# Does a root contain a user-owned entry? A symlink is evidence but is never traversed.
sub _root_has_evidence {
  my ( $root, $classify ) = @_;
  return 0 unless lstat( encode_text($root) );
  return 1 if -l _ || !-d _;
  my $visit;
  $visit = sub {
    my ( $dir, $prefix ) = @_;
    opendir( my $dh, encode_text($dir) ) or return 0;
    my @names = map { decode_utf8_lossy($_) } grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    for my $name (@names) {
      my $rel = length $prefix ? $prefix.'/'.$name : $name;
      my $abs = path_join( $dir, $name );
      next unless lstat( encode_text($abs) );
      my $link = -l _ ? 1 : 0;
      my $directory = -d _ ? 1 : 0;
      my $verdict = $classify->( $rel, $abs, $directory );
      next if $verdict eq 'skip';
      return 1 if $verdict eq 'evidence' || $link || !$directory;
      return 1 if $visit->( $abs, $rel );
    }
    return 0;
  };
  return $visit->( $root, '' );
}

sub _owned_skills {
  my ( $lock, $harness ) = @_;
  my %owned;
  for my $key ( keys %$lock ) {
    my $parsed = parse_lock_key($key);
    $owned{ $parsed->{target} } = 1
      if defined $parsed->{harness} && $parsed->{harness} eq $harness && $parsed->{type} eq 'skill';
  }
  return \%owned;
}

sub _owned_files {
  my ( $lock, $harness, @types ) = @_;
  my %type = map { $_ => 1 } @types;
  my %owned;
  for my $key ( keys %$lock ) {
    my $parsed = parse_lock_key($key);
    next unless defined $parsed->{harness} && $parsed->{harness} eq $harness && $type{ $parsed->{type} };
    my $entry = $lock->{$key};
    next unless js_type($entry) eq 'object' && js_type( $entry->{files} ) eq 'object';
    $owned{$_} = 1 for keys %{ $entry->{files} };
  }
  return \%owned;
}

sub _in_owned_skill {
  my ( $rel, $owned ) = @_;
  for my $target ( keys %$owned ) { return 1 if $rel eq $target || index( $rel, $target.'/' ) == 0 }
  return 0;
}

sub _generated_skill_dir {
  my ( $rel, $abs, $directory ) = @_;
  return 0 unless $directory && $rel =~ m{\Askills/[^/]+\z};
  my $text = eval { read_text( path_join( $abs, '.gitignore' ) ) };
  return defined $text && $text eq SKILL_GITIGNORE ? 1 : 0;
}

# Empty settings and settings containing only skilletor-generated plugin/marketplace declarations
# are not evidence. Malformed settings or any other key is Claude evidence.
sub _claude_settings_are_evidence {
  my ( $path, $text ) = @_;
  my $settings = eval { js_parse( $text // read_text($path) ) };
  return 1 unless $settings && js_type($settings) eq 'object';
  return 1 if grep { $_ ne 'enabledPlugins' && $_ ne 'extraKnownMarketplaces' } keys %$settings;
  my $enabled = $settings->{enabledPlugins};
  my $markets = $settings->{extraKnownMarketplaces};
  return 1 if exists $settings->{enabledPlugins} && js_type($enabled) ne 'object';
  return 1 if exists $settings->{extraKnownMarketplaces} && js_type($markets) ne 'object';
  my @enabled = keys %{ $enabled // {} };
  my @markets = keys %{ $markets // {} };
  return @markets ? 1 : 0 unless @enabled;
  return 1 unless @enabled == 1;
  my $key = $enabled[0];
  my $at = rindex( $key, '@' );
  return 1 if $at <= 0 || $at == length($key) - 1 || substr( $key, 0, $at ) ne 'skilletor';
  return 1 unless js_type( $enabled->{$key} ) eq 'boolean' && $enabled->{$key};
  my $market = substr( $key, $at + 1 );
  return ( grep { $_ ne $market } @markets ) ? 1 : 0;
}

# A direct skill entry is evidence only when linked or when it contains SKILL.md. A leftover
# directory containing unrelated foreign files must not re-enable its harness.
sub _skill_evidence_verdict {
  my ( $rel, $abs, $directory ) = @_;
  return undef unless $rel =~ m{\Askills/[^/]+\z};
  return _path_is_link($abs) ? 'evidence' : 'skip' unless $directory;
  return _path_is_evidence( path_join( $abs, 'SKILL.md' ) ) ? 'evidence' : 'skip';
}

# Project-local harness evidence (k229), excluding current lock ownership and fixed generated
# artifacts so a sync cannot opt another harness in on its next run.
# $settings_text substitutes a proposed .claude/settings.json in memory, even if absent on disk.
sub detect_project_harnesses {
  my ( $project_dir, $lock, $settings_text ) = @_;
  my %evidence;
  my $claude_owned = _owned_skills( $lock, 'claude' );
  my $claude_files = _owned_files( $lock, 'claude', qw( skill agent rule ) );
  my $projected_settings = defined $settings_text
    ? !$claude_files->{'settings.json'} && _claude_settings_are_evidence( path_join( $project_dir, '.claude', 'settings.json' ), $settings_text )
    : undef;
  my $claude = _path_is_evidence( path_join( $project_dir, 'CLAUDE.md' ) ) || $projected_settings || _root_has_evidence(
    path_join( $project_dir, '.claude' ),
    sub {
      my ( $rel, $abs, $directory ) = @_;
      return 'skip' if grep { $rel eq $_ } qw( skilletor.json skilletor.local.json skilletor.lock.json .gitignore skilletor );
      return 'skip' if $claude_files->{$rel};
      return ( $projected_settings // _claude_settings_are_evidence($abs) ) ? 'evidence' : 'skip' if $rel eq 'settings.json';
      return 'skip' if _in_owned_skill( $rel, $claude_owned ) || _generated_skill_dir( $rel, $abs, $directory );
      my $skill = _skill_evidence_verdict( $rel, $abs, $directory );
      return $skill if defined $skill;
      my @parts = split m{/}, $rel;
      return 'skip' if ( $parts[0] eq 'agents' || $parts[0] eq 'rules' ) && $parts[-1] =~ /\A\.local\./;
      return 'inspect';
    },
  );
  $evidence{claude} = 1 if $claude;

  my $codex_owned = _owned_skills( $lock, 'codex' );
  my $codex_files = _owned_files( $lock, 'codex', qw( agent rule ) );
  my $agents = _root_has_evidence(
    path_join( $project_dir, '.agents' ),
    sub {
      my ( $rel, $abs, $directory ) = @_;
      my ($top) = split m{/}, $rel;
      return 'skip' if $rel eq '.gitignore' || $top ne 'skills';
      return 'skip' if _in_owned_skill( $rel, $codex_owned ) || _generated_skill_dir( $rel, $abs, $directory );
      return _skill_evidence_verdict( $rel, $abs, $directory ) // 'inspect';
    },
  );
  my $codex = _root_has_evidence(
    path_join( $project_dir, '.codex' ),
    sub {
      my ( $rel ) = @_;
      return 'skip' if $rel eq '.gitignore' || $rel eq 'skilletor-rules.md' || $codex_files->{$rel};
      my @parts = split m{/}, $rel;
      return 'skip' if $parts[0] eq 'agents' && $parts[-1] =~ /\A\.local\./;
      return 'inspect';
    },
  );
  $evidence{codex} = 1 if $agents || $codex || _path_is_evidence( path_join( $project_dir, 'AGENTS.override.md' ) );

  my $hermes_owned = _owned_skills( $lock, 'hermes' );
  my $hermes = _root_has_evidence(
    path_join( $project_dir, '.hermes' ),
    sub {
      my ( $rel, $abs, $directory ) = @_;
      return 'skip' if $rel eq '.gitignore';
      return 'skip' if _in_owned_skill( $rel, $hermes_owned ) || _generated_skill_dir( $rel, $abs, $directory );
      return _skill_evidence_verdict( $rel, $abs, $directory ) // 'inspect';
    },
  );
  $evidence{hermes} = 1 if $hermes;
  return [ grep { $evidence{$_} } HARNESSES ];
}

# Hermes' default home: ~/.hermes; on native Windows %LOCALAPPDATA%\hermes.
sub default_hermes_home {
  my ( $home, $platform, $env ) = @_;
  $platform //= $^O;
  $env //= \%ENV;
  return path_join( $home, '.hermes' ) unless $platform eq 'MSWin32';
  my $local = js_trim( $env->{LOCALAPPDATA} // '' );
  $local = $home.'\\AppData\\Local' unless length $local;
  ( my $joined = $local.'\\hermes' ) =~ s{[\\/]+}{\\}g;
  return $joined;
}

# Machine = user targets // detected (empty is an error); user scope gets that set. Explicit
# project targets win; otherwise evidence decides, with one-target bootstrap and an explicit
# unresolved signal for an ambiguous multi-target project.
sub select_targets {
  my ( $configured, $detected, $markers ) = @_;
  my $machine = $configured->{user} // $detected;
  unless (@$machine) {
    my $looked = $markers
      ? ' (looked for '.join( '; ', map { $_.': '.join( ', ', @{ $markers->{$_} } ) } grep { $markers->{$_} } DETECTED ).')'
      : '';
    Skilletor::Error::Target->throw( 'no agent harness detected'.$looked
      .'; set "targets": ["claude"], "codex" and/or "hermes" in ~/.claude/skilletor.json' );
  }
  my @warnings;
  my $project = [@$machine];
  my $unresolved;
  if ( my $want = $configured->{project} ) {
    my %in = map { $_ => 1 } @$want;
    $project = [ grep { $in{$_} } @$machine ];
    unless (@$project) {
      push @warnings, 'project targets ('.join( ', ', @$want ).') are not in use on this machine '
        .'('.join( ', ', @$machine ).'); nothing is installed for the project';
    }
  }
  elsif ( exists $configured->{project_evidence} ) {
    my $evidence = $configured->{project_evidence};
    if (@$evidence) {
      my %in = map { $_ => 1 } @$evidence;
      $project = [ grep { $in{$_} } @$machine ];
      unless (@$project) {
        push @warnings, 'project harness evidence ('.join( ', ', @$evidence ).') is not in use on this machine '
          .'('.join( ', ', @$machine ).'); nothing is installed for the project';
      }
    }
    elsif ( @$machine == 1 ) {
      $project = [@$machine];
    }
    else {
      $project = [@$machine];
      $unresolved = 1;
      push @warnings, 'project targets are ambiguous: no project-local harness evidence for machine targets ('
        .join( ', ', @$machine ).'); set "targets" in the project\'s .claude/skilletor.json or '
        .'.claude/skilletor.local.json; project scope is left unchanged';
    }
  }
  return { user => [@$machine], project => $project, warnings => \@warnings, ( $unresolved ? ( project_unresolved => 1 ) : () ) };
}

#### The layout table (spec §14.2, §16.2) ##############################
#
# Where each harness reads each item type. The Perl port writes for Claude Code and Codex, but the
# table is whole: the managed blocks list every harness's roots (spec §6.4), and lock keys of
# every harness are parsed, kept or reported as the reference does.

sub _under { my ( $dir ) = @_; return sub { path_join( $_[0]{base}, $dir ) } }

sub _claude_root {
  my ( $r ) = @_;
  return ( $r->{scope} eq 'user' && defined $r->{claude_dir} && length $r->{claude_dir} ) ? $r->{claude_dir} : path_join( $r->{base}, '.claude' );
}

sub _codex_home_dir {
  my ( $r ) = @_;
  return ( defined $r->{codex_home} && length $r->{codex_home} ) ? $r->{codex_home} : path_join( $r->{base}, '.codex' );
}

sub _codex_root {
  my ( $r ) = @_;
  return $r->{scope} eq 'user' ? _codex_home_dir($r) : path_join( $r->{base}, '.codex' );
}

sub _hermes_root {
  my ( $r ) = @_;
  return path_join( $r->{base}, '.hermes' ) unless $r->{scope} eq 'user';
  return ( defined $r->{hermes_home} && length $r->{hermes_home} ) ? $r->{hermes_home} : default_hermes_home( $r->{base} );
}

# roots: [ type => root function ] in the reference's order.
my %LAYOUTS = (
  claude => {
    prefix      => '',
    roots       => [ skill => \&_claude_root, agent => \&_claude_root, rule => \&_claude_root ],
    local_types => { agent => 1, rule => 1 },
  },
  codex => {
    prefix      => 'codex:',
    roots       => [ skill => _under('.agents'), agent => \&_codex_root, rule => \&_codex_root ],
    block_types => { rule => 1 },
    local_types => { agent => 1 },
  },
  hermes => {
    prefix             => 'hermes:',
    roots              => [ skill => \&_hermes_root ],
    project_via        => { skill => 'codex' },
    no_gitignore_block => 1,
  },
);

sub _root_fn {
  my ( $harness, $type ) = @_;
  my @pairs = @{ $LAYOUTS{$harness}{roots} };
  while ( my ( $t, $fn ) = splice @pairs, 0, 2 ) { return $fn if $t eq $type }
  return undef;
}

sub lock_key {
  my ( $harness, $target ) = @_;
  return $LAYOUTS{$harness}{prefix}.$target;
}

sub supports {
  my ( $harness, $type ) = @_;
  return ( $LAYOUTS{$harness} && _root_fn( $harness, $type ) ) ? 1 : 0;
}

sub root_of {
  my ( $rc, $harness, $type ) = @_;
  my $fn = _root_fn( $harness, $type ) or return undef;
  return $fn->($rc);
}

sub root_of_key {
  my ( $rc, $key ) = @_;
  my $k = parse_lock_key($key);
  return defined $k->{harness} ? root_of( $rc, $k->{harness}, $k->{type} ) : undef;
}

sub served_via {
  my ( $active, $harness, $type, $scope ) = @_;
  my $via = $scope eq 'project' ? ( $LAYOUTS{$harness}{project_via} // {} )->{$type} : undef;
  return ( defined $via && grep { $_ eq $via } @$active ) ? $via : undef;
}

sub receivers {
  my ( $active, $type, $scope ) = @_;
  return [ grep { supports( $_, $type ) && !defined served_via( $active, $_, $type, $scope ) } @$active ];
}

sub is_block_type {
  my ( $harness, $type ) = @_;
  return ( $LAYOUTS{$harness}{block_types} // {} )->{$type} ? 1 : 0;
}

sub is_local_type {
  my ( $harness, $type ) = @_;
  return ( $LAYOUTS{$harness}{local_types} // {} )->{$type} ? 1 : 0;
}

# Every distinct root of a scope that can hold a gitignore block, in the reference's order.
sub all_roots {
  my ( $rc ) = @_;
  my ( %seen, @out );
  for my $h (HARNESSES) {
    next if $LAYOUTS{$h}{no_gitignore_block};
    my @pairs = @{ $LAYOUTS{$h}{roots} };
    while ( my ( undef, $fn ) = splice @pairs, 0, 2 ) {
      my $root = $fn->($rc);
      push @out, $root unless $seen{$root}++;
    }
  }
  return @out;
}

# Where the lock disagrees with the active targets: an entry of a harness that gets no copy
# (`key` alone), or an item an active receiving harness lacks (`missing`).
sub target_gaps {
  my ( $keys, $active, $scope ) = @_;
  $scope //= 'user';
  my %set = map { $_ => 1 } @$keys;
  my @gaps;
  for my $key (@$keys) {
    my $k = parse_lock_key($key);
    next unless defined $k->{harness} && supports( $k->{harness}, $k->{type} );
    my $receiving = receivers( $active, $k->{type}, $scope );
    unless ( grep { $_ eq $k->{harness} } @$receiving ) {
      push @gaps, { key => $key };
      next;
    }
    for my $h (@$receiving) {
      my $missing = lock_key( $h, $k->{target} );
      push @gaps, { key => $key, missing => $missing } unless $set{$missing};
    }
  }
  return \@gaps;
}

use constant LOCAL_PREFIX => '.local.';

sub _cut { my ( $rel ) = @_; my $s = rindex( $rel, '/' ); my $b = rindex( $rel, '\\' ); return ( $s > $b ? $s : $b ) + 1 }

# An item's output as the harness installs it: `.local.` file names for its local types, and
# the plain paths the item still claims. $output: [ [ rel, bytes ], ... ].
sub place_output {
  my ( $harness, $type, $output ) = @_;
  return { output => $output, claims => [] } unless is_local_type( $harness, $type );
  my ( @placed, @claims );
  for my $pair (@$output) {
    my ( $rel, $bytes ) = @$pair;
    my $cut = _cut($rel);
    push @placed, [ substr( $rel, 0, $cut ).LOCAL_PREFIX.substr( $rel, $cut ), $bytes ];
    push @claims, $rel;
  }
  return { output => \@placed, claims => \@claims };
}

sub lacks_local_prefix {
  my ( $harness, $type, $paths ) = @_;
  return 0 unless is_local_type( $harness, $type );
  return ( grep { index( substr( $_, _cut($_) ), LOCAL_PREFIX ) != 0 } @$paths ) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Targets - Which agent harnesses a sync installs for (detection and the targets merge)

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Targets qw( default_markers detect_harnesses select_targets );

  my $markers = default_markers( $home, $ENV{CODEX_HOME} );
  my $sel = select_targets(
    {
      user => $config->user->{targets},
      project => $config->project && $config->project->{targets},
      project_evidence => detect_project_harnesses( $project_dir, $lock ),
    },
    detect_harnesses($markers),
    $markers,
  );
  # { user => ['claude'], project => ['claude'], warnings => [] }

=head1 DESCRIPTION

The detection and target selection of the reference's C<targets.ts>
(spec §14.1). A harness is detected by markers it creates itself, never by
C<~/.claude> alone.

It also holds the reference's layout table (C<LAYOUTS>, spec §14.2, §16.2):
where each harness reads each item type in each scope, how a lock key names its
harness, which types install as C<.local.> files. The Perl port writes for
all three harnesses, Claude Code, Codex and Hermes. The project's
C<.worktreeinclude> block lists every harness's roots; the C<.gitignore>
blocks never go into a Hermes root (C<all_roots> skips it: an installed
skill carries its own C<.gitignore>). Lock keys of every harness are parsed,
kept and reported as the reference does.

A root context (C<$rc>) is C<< { base, scope, claude_dir?, codex_home?,
hermes_home? } >>: the scope's base (the home or the project root), Claude
Code's config dir (user scope), C<$CODEX_HOME> and the Hermes home, each empty
for its default.

=head2 default_markers

  default_markers( $home, $codex_home );

C<< { claude => [...], codex => [...] } >>: the paths whose existence means the
harness is in use.

=head2 detect_harnesses

The detected harnesses, in the order C<claude>, C<codex>.

=head2 detect_project_harnesses

  detect_project_harnesses( $project_dir, $lock );

The harness evidence owned by the project, excluding paths the current lock or
skilletor's generated naming and marker conventions identify as its own output.
Symlink roots count but are not traversed.

=head2 select_targets

  select_targets( { user => $u, project => $p, project_evidence => $e }, $detected, $markers );

C<< { user => [...], project => [...], warnings => [...], project_unresolved? => 1 } >>;
explicit project targets win over evidence, one machine target bootstraps without
evidence, and an ambiguous multi-target project is marked unresolved. Throws
L<Skilletor::Error::Target> when no harness applies.

=head2 default_hermes_home

  default_hermes_home( $home, $platform, \%env );

=head2 lock_key

  lock_key( codex => 'skills/foo' );   # codex:skills/foo

=head2 supports

True when the harness has a place for the type.

=head2 root_of

  root_of( $rc, $harness, $type );   # undef when the harness takes no such type

=head2 root_of_key

The root a lock key's files live under; undef for an unknown prefix or type.

=head2 served_via

  served_via( $active, $harness, $type, $scope );

The other active harness whose copy serves this one (Hermes reads a project
skill through the Codex copy), or undef.

=head2 receivers

  receivers( $active, $type, $scope );   # [ the harnesses that get a copy of their own ]

=head2 is_block_type

=head2 is_local_type

=head2 all_roots

  my @roots = all_roots($rc);

Every distinct root of a scope that can hold a C<.gitignore> block, in the
reference's order; never a Hermes root.

=head2 target_gaps

  target_gaps( $keys, $active, $scope );   # [ { key }, { key, missing } ]

=head2 place_output

  place_output( claude => agent => [ [ 'agents/x.md', $bytes ] ] );
  # { output => [ [ 'agents/.local.x.md', $bytes ] ], claims => [ 'agents/x.md' ] }

=head2 lacks_local_prefix

True when an item of a C<.local.> type owns a file without the prefix.

=head2 DETECTED

The harnesses detection looks for: C<claude>, C<codex>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
