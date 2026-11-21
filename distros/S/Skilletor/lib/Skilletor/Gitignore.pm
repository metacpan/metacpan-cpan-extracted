package Skilletor::Gitignore;
# ABSTRACT: Managed .gitignore and .worktreeinclude blocks, skill .gitignore files, git's view (spec §6.4)

use strict;
use warnings;

use Encode ();
use Exporter qw( import );
use Skilletor::FSUtil qw( encode_text path_join read_text write_text );
use Skilletor::GitEnv qw( git_env );
use Skilletor::JSON qw( js_sort_keys );
use Skilletor::Process qw( run_command );

our $VERSION = '0.008000';

our @EXPORT_OK = qw(
  SKILL_GITIGNORE PROJECT_CLAUDE_ENTRIES LOCAL_ENTRIES CODEX_ENTRIES WORKTREE_INCLUDE
  update_gitignore update_worktree_include block_entries has_block
  skill_gitignore_path with_skill_gitignore git_tracked is_git_work_tree
);

use constant BEGIN_LINE => '# >>> skilletor >>>';
use constant END_LINE   => '# <<< skilletor <<<';

use constant SKILL_GITIGNORE => qq{# installed by skilletor, not committed ("gitignore": false in skilletor.json to commit)\n*\n};
use constant PROJECT_CLAUDE_ENTRIES => qw( skilletor.lock.json skilletor.local.json agents/**/.local.* rules/**/.local.* );
use constant LOCAL_ENTRIES          => qw( agents/**/.local.* rules/**/.local.* );
use constant CODEX_ENTRIES          => qw( agents/**/.local.* skilletor-rules.md );
use constant WORKTREE_INCLUDE       => '.worktreeinclude';

sub update_gitignore {
  my ( %opts ) = @_;
  return _update_block_file( path_join( $opts{dir}, '.gitignore' ), %opts );
}

sub update_worktree_include {
  my ( %opts ) = @_;
  return _update_block_file( path_join( $opts{dir}, WORKTREE_INCLUDE ), %opts );
}

# Lines without their CRLF/LF endings, with exact offsets for surgical edits.
sub _text_lines {
  my ( $text ) = @_;
  my @lines;
  my $start = 0;
  while ( $start < length $text ) {
    my $newline = index( $text, "\n", $start );
    if ( $newline == -1 ) {
      push @lines, { text => substr( $text, $start ), start => $start, end => length($text), eol => '' };
      last;
    }
    my $content_end = $newline > $start && substr( $text, $newline - 1, 1 ) eq "\r" ? $newline - 1 : $newline;
    push @lines, {
      text  => substr( $text, $start, $content_end - $start ),
      start => $start,
      end   => $newline + 1,
      eol   => substr( $text, $content_end, $newline + 1 - $content_end ),
    };
    $start = $newline + 1;
  }
  return @lines;
}

sub _block_of {
  my ( $lines ) = @_;
  my ( $begin, $end ) = ( -1, -1 );
  for my $i ( 0 .. $#$lines ) {
    $begin = $i if $begin == -1 && $lines->[$i]{text} eq BEGIN_LINE;
    $end   = $i if $end == -1   && $lines->[$i]{text} eq END_LINE;
  }
  return ( $begin, $end, ( $begin != -1 && $end != -1 && $end > $begin ) ? 1 : 0 );
}

sub block_entries {
  my ( $path ) = @_;
  my $lines = eval { [ _text_lines( read_text($path) ) ] } or return ();
  my ( $begin, $end, $has ) = _block_of($lines);
  return $has ? map { $lines->[$_]{text} } $begin + 1 .. $end - 1 : ();
}

sub has_block {
  my ( $dir ) = @_;
  my $lines = eval { [ _text_lines( read_text( path_join( $dir, '.gitignore' ) ) ) ] } or return 0;
  return ( _block_of($lines) )[2];
}

sub _ends_with {
  my ( $text, $suffix ) = @_;
  return length($suffix) <= length($text) && substr( $text, -length($suffix) ) eq $suffix;
}

sub _update_block_file {
  my ( $path, %opts ) = @_;
  my $bytes    = encode_text($path);
  my $existed  = -e $bytes;
  my $existing = $existed ? read_text($path) : '';
  my @lines    = _text_lines($existing);
  my ( $begin, $end, $has ) = _block_of( \@lines );
  my %seen;
  my @entries = js_sort_keys( grep { !$seen{$_}++ } @{ $opts{entries} } );
  my $write = $opts{enabled} && @entries;
  my ( $result, $change ) = ( $existing, undef );

  if ($has) {
    my @current = map { $lines[$_]{text} } $begin + 1 .. $end - 1;
    my $same = @current == @entries;
    for my $i ( 0 .. $#entries ) { $same = 0 if !$same || $current[$i] ne $entries[$i] }
    return 'unchanged' if $write && $same;
    my ( $first, $last ) = ( $lines[$begin], $lines[$end] );
    if ($write) {
      my ($with_eol) = grep { length $_->{eol} } @lines;
      my $newline = $first->{eol} || $last->{eol} || ( $with_eol ? $with_eol->{eol} : "\n" );
      my $replacement = join( $newline, BEGIN_LINE, @entries, END_LINE ).$last->{eol};
      $result = substr( $existing, 0, $first->{start} ).$replacement.substr( $existing, $last->{end} );
      $change = 'changed';
    }
    else {
      my $before = substr( $existing, 0, $first->{start} );
      my $after  = substr( $existing, $last->{end} );
      $result = $before.$after;
      $change = 'removed';
    }
  }
  elsif ($write) {
    my ($with_eol) = grep { length $_->{eol} } @lines;
    my $newline = $with_eol ? $with_eol->{eol} : "\n";
    my $separator = '';
    if ( length $existing ) {
      $separator = _ends_with( $existing, $newline.$newline ) ? '' : _ends_with( $existing, $newline ) ? $newline : $newline.$newline;
    }
    $result = $existing.$separator.join( $newline, BEGIN_LINE, @entries, END_LINE ).$newline;
    $change = 'created';
  }
  else {
    return 'unchanged';
  }

  if ( $result eq '' ) {
    unlink $bytes if $existed;
    return $change;
  }
  write_text( $path, $result ) if $result ne $existing;
  return $change;
}

sub skill_gitignore_path {
  my ( $name ) = @_;
  return path_join( 'skills', $name, '.gitignore' );
}

# The output with skilletor's `.gitignore` at the skill's root, replacing one the source ships
# there: [ [ rel, bytes ], ... ], order kept.
sub with_skill_gitignore {
  my ( $output, $name ) = @_;
  my $rel   = skill_gitignore_path($name);
  my $bytes = encode_text(SKILL_GITIGNORE);
  my $found = 0;
  my @out   = map { $_->[0] eq $rel ? do { $found = 1; [ $rel, $bytes ] } : $_ } @$output;
  push @out, [ $rel, $bytes ] unless $found;
  return \@out;
}

use constant LS_FILES_BATCH => 500;

sub _git {
  my ( @args ) = @_;
  my $r = eval { run_command( cmd => [ 'git', @args ], env => git_env(), timeout_ms => 5_000 ) };
  return ( $r && !$r->{spawn_error} && !$r->{timed_out} && defined $r->{code} && $r->{code} == 0 ) ? $r->{stdout} : undef;
}

# Which of `paths` (relative to $dir) git tracks: one `git ls-files` per 500 paths. Outside a
# work tree, or when git is missing or fails, none.
sub git_tracked {
  my ( $dir, $paths ) = @_;
  my @out;
  for ( my $i = 0; $i < @$paths; $i += LS_FILES_BATCH ) {
    my $last = $i + LS_FILES_BATCH - 1;
    $last = $#$paths if $last > $#$paths;
    my $listed = _git( '-C', $dir, '--literal-pathspecs', 'ls-files', '-z', '--', @{$paths}[ $i .. $last ] );
    return [] unless defined $listed;
    push @out, map { Encode::decode( 'UTF-8', $_ ) } grep { length } split /\0/, $listed;
  }
  return \@out;
}

sub is_git_work_tree {
  my ( $dir ) = @_;
  my $out = _git( '-C', $dir, 'rev-parse', '--is-inside-work-tree' );
  return ( defined $out && $out =~ /\A\s*true\s*\z/ ) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Gitignore - Managed .gitignore and .worktreeinclude blocks, skill .gitignore files, git's view (spec §6.4)

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Gitignore qw( update_gitignore PROJECT_CLAUDE_ENTRIES );

  my $change = update_gitignore( dir => "$project/.claude", entries => [PROJECT_CLAUDE_ENTRIES], enabled => 1 );
  # 'created', 'changed', 'removed' or 'unchanged'

=head1 DESCRIPTION

The reference's C<gitignore.ts> (spec §6.4). The ignore rules are fixed, so a
committed C<.gitignore> does not change with the installed items: every
installed skill directory carries its own C<.gitignore> (L</SKILL_GITIGNORE>),
and agents and rules install as C<.local.> files that fixed patterns cover. A
target root's C<.gitignore> holds one block between C<< # >>> skilletor >>> >>
and C<< # <<< skilletor <<< >>, its entries sorted; text outside it is never
touched, a block without entries is removed, and a file left empty is deleted.
The project root's C<.worktreeinclude> gets a block of the same form.

=head2 update_gitignore

  update_gitignore( dir => $root, entries => \@entries, enabled => $bool );

=head2 update_worktree_include

The same for C<< <dir>/.worktreeinclude >>.

=head2 block_entries

  my @entries = block_entries($file);   # none for a missing file or one without a block

=head2 has_block

True when C<< <dir>/.gitignore >> holds a skilletor block.

=head2 skill_gitignore_path

  skill_gitignore_path('foo');   # skills/foo/.gitignore

=head2 with_skill_gitignore

  with_skill_gitignore( $output, 'foo' );

The output (C<[ [ rel, bytes ], ... ]>) with skilletor's C<.gitignore> at the
skill's root, replacing one the source ships.

=head2 git_tracked

  git_tracked( $dir, \@paths );   # the ones git tracks

=head2 is_git_work_tree

True when C<$dir> lies inside a git work tree; git missing or failing counts
as no. Both git questions run with L<Skilletor::GitEnv/git_env>, so an exported
C<GIT_DIR> never decides them.

=head2 SKILL_GITIGNORE

=head2 PROJECT_CLAUDE_ENTRIES

=head2 LOCAL_ENTRIES

=head2 CODEX_ENTRIES

=head2 WORKTREE_INCLUDE

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
