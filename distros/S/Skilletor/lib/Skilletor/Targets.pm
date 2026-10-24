package Skilletor::Targets;
# ABSTRACT: Which agent harnesses a sync installs for (detection and the targets merge)

use strict;
use warnings;

use Exporter qw( import );
use Skilletor::Entry qw( HARNESSES );
use Skilletor::Error::Target;
use Skilletor::FSUtil qw( path_join );
use Skilletor::JSString qw( js_trim );
use Skilletor::Lock qw( parse_lock_key );

our $VERSION = '0.001';

our @EXPORT_OK = qw(
  DETECTED default_markers detect_harnesses select_targets default_hermes_home
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

# The merge rule (spec §14.1): machine = user targets // detected (empty is an error); the user
# scope gets the machine set; the project scope the machine set narrowed to the project's.
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
  if ( my $want = $configured->{project} ) {
    my %in = map { $_ => 1 } @$want;
    $project = [ grep { $in{$_} } @$machine ];
    unless (@$project) {
      push @warnings, 'project targets ('.join( ', ', @$want ).') are not in use on this machine '
        .'('.join( ', ', @$machine ).'); nothing is installed for the project';
    }
  }
  return { user => [@$machine], project => $project, warnings => \@warnings };
}

#### The layout table (spec §14.2, §16.2) ##############################
#
# Where each harness reads each item type. The Perl port writes for Claude Code alone, but the
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

version 0.001

=head1 SYNOPSIS

  use Skilletor::Targets qw( default_markers detect_harnesses select_targets );

  my $markers = default_markers( $home, $ENV{CODEX_HOME} );
  my $sel = select_targets(
    { user => $config->user->{targets}, project => $config->project && $config->project->{targets} },
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
Claude Code alone; the table is whole because the managed blocks list every
harness's roots and lock keys of every harness are parsed, kept and reported as
the reference does.

A root context (C<$rc>) is C<< { base, scope, codex_home?, hermes_home? } >>:
the scope's base (the home or the project root), C<$CODEX_HOME> and the Hermes
home, either empty for its default.

=head2 default_markers

  default_markers( $home, $codex_home );

C<< { claude => [...], codex => [...] } >>: the paths whose existence means the
harness is in use.

=head2 detect_harnesses

The detected harnesses, in the order C<claude>, C<codex>.

=head2 select_targets

  select_targets( { user => $u, project => $p }, $detected, $markers );

C<< { user => [...], project => [...], warnings => [...] } >>; throws
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

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
