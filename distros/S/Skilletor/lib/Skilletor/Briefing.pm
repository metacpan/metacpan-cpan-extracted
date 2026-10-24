package Skilletor::Briefing;
# ABSTRACT: Are an installed agent's briefing skills there? (spec §6.7)

use strict;
use warnings;
use utf8;

use Encode ();
use Exporter qw( import );
use Skilletor::FSUtil qw( encode_text path_join read_text );
use Skilletor::Frontmatter qw( split_frontmatter );
use Skilletor::JSON qw( js_sort_keys js_type );

our $VERSION = '0.001';

our @EXPORT_OK = qw( declared_skills skill_roots missing_skills briefing_warning );

# briefing's own matcher for the Codex comment line (spec §14.7).
my $COMMENT = qr/\A[ \t]*#[ \t]*briefing:[ \t]*skills[ \t]*=[ \t]*\[([^\]\r\n]*)\]/;

# The skills an installed agent file declares; undef when it cannot be read.
sub declared_skills {
  my ( $harness, $text ) = @_;
  if ( $harness eq 'codex' ) {
    for my $line ( split /\n/, $text, -1 ) {
      last if $line =~ /\Adeveloper_instructions[ \t]*=/;
      next unless $line =~ $COMMENT;
      my $list = $1;
      my @out;
      push @out, defined $1 ? $1 : $2 while $list =~ /"([^"]*)"|'([^']*)'/g;
      return \@out;
    }
    return [];
  }
  my $fm = eval { split_frontmatter($text) } or return undef;
  my $briefing = $fm->{data}{briefing};
  return [] unless js_type($briefing) eq 'object';
  my $skills = $briefing->{skills};
  return [] unless js_type($skills) eq 'array';
  return [ grep { !ref $_ && js_type($_) eq 'string' && length } @$skills ];
}

sub _subdirs {
  my ( $dir ) = @_;
  opendir( my $dh, encode_text($dir) ) or return ();
  my @names = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
  closedir $dh;
  return js_sort_keys( grep { my $p = encode_text( path_join( $dir, $_ ) ); !-l $p && -d $p } map { Encode::decode( 'UTF-8', $_ ) } @names );
}

# <claude config dir>/plugins/cache/*/skills and …/cache/*/*/skills, as far as they exist.
sub _plugin_cache_roots {
  my ( $claude_dir ) = @_;
  my $cache = path_join( $claude_dir, 'plugins', 'cache' );
  my @out;
  for my $a ( _subdirs($cache) ) {
    push @out, path_join( $cache, $a, 'skills' );
    push @out, path_join( $cache, $a, $_, 'skills' ) for _subdirs( path_join( $cache, $a ) );
  }
  return @out;
}

# The skill roots the harness's briefing lookup searches for an agent of this scope.
# $r: { home, claude_dir?, codex_home?, project_dir? }; claude_dir defaults to <home>/.claude.
sub skill_roots {
  my ( $harness, $scope, $r ) = @_;
  my $project = ( $scope eq 'project' && defined $r->{project_dir} && length $r->{project_dir} ) ? $r->{project_dir} : undef;
  if ( $harness eq 'codex' ) {
    my $codex_home = ( defined $r->{codex_home} && length $r->{codex_home} ) ? $r->{codex_home} : path_join( $r->{home}, '.codex' );
    my @user = ( path_join( $codex_home, 'skills' ), path_join( $r->{home}, '.agents', 'skills' ) );
    return $project ? [ path_join( $project, '.agents', 'skills' ), path_join( $project, '.codex', 'skills' ), @user ] : \@user;
  }
  my $claude_dir = ( defined $r->{claude_dir} && length $r->{claude_dir} ) ? $r->{claude_dir} : path_join( $r->{home}, '.claude' );
  return [ ( $project ? path_join( $project, '.claude', 'skills' ) : () ), path_join( $claude_dir, 'skills' ),
    _plugin_cache_roots($claude_dir) ];
}

# Bare declared skill names of the agent file that resolve in none of the roots; undef when the
# file cannot be read or parsed.
sub missing_skills {
  my ( $harness, $file, $roots ) = @_;
  my $text = eval { read_text($file) };
  return undef unless defined $text;
  my $declared = declared_skills( $harness, $text ) or return undef;
  my @missing;
  for my $name (@$declared) {
    next if index( $name, ':' ) >= 0 || grep { $_ eq $name } @missing;
    # A name that is not one path segment resolves nowhere (and is never probed).
    my $segment = $name !~ m{[\\/]} && $name ne '.' && $name ne '..';
    push @missing, $name if !$segment || !grep { -e encode_text( path_join( $_, $name, 'SKILL.md' ) ) } @$roots;
  }
  return \@missing;
}

sub briefing_warning {
  my ( $name, $harness, $missing ) = @_;
  return 'agent '.$name.' ('.$harness.'): briefing skills not installed: '.join( ', ', @$missing ).' — '
    .'install them, or ship the agent and its skills together as a bundle';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Briefing - Are an installed agent's briefing skills there? (spec §6.7)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Briefing qw( skill_roots missing_skills briefing_warning );

  my $roots   = skill_roots( claude => project => { home => $home, project_dir => $project } );
  my $missing = missing_skills( claude => "$project/.claude/agents/.local.reviewer.md", $roots );
  print briefing_warning( 'reviewer', 'claude', $missing ), "\n" if $missing && @$missing;

=head1 DESCRIPTION

The reference's C<briefing.ts> (spec §6.7). An agent may declare skills for the
briefing plugin (C<< briefing: { skills: [...] } >> in its frontmatter); one
installed without them fails when it is spawned. This reads the installed
agent file – never renders it – and names the bare skill names no root the
harness's briefing lookup searches holds: for Claude Code the project's
C<.claude/skills> (a project agent), C<~/.claude/skills> and Claude Code's
plugin cache. C<plugin:skill> names are not checked. Read-only; a file it
cannot parse yields nothing.

=head2 declared_skills

  declared_skills( claude => $text );   # [ names ], or undef when the frontmatter cannot be read

=head2 skill_roots

  skill_roots( $harness, $scope, { home, codex_home?, project_dir? } );

=head2 missing_skills

  missing_skills( $harness, $file, $roots );   # [ names ], or undef

=head2 briefing_warning

The report line for one agent and target.

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
