package Skilletor::Gitignore;
# ABSTRACT: Managed .gitignore and .worktreeinclude blocks, skill .gitignore files, git's view (spec §6.4)

use strict;
use warnings;

use Encode ();
use Exporter qw( import );
use Skilletor::FSUtil qw( encode_text path_join read_text write_text );
use Skilletor::GitEnv qw( git_env );
use Skilletor::JSON qw( js_sort_keys );
use Skilletor::JSString qw( js_blank );
use Skilletor::Process qw( run_command );

our $VERSION = '0.001';

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

# JavaScript's "a\nb".split("\n") (a trailing newline gives a final "").
sub _lines { my ( $text ) = @_; return split /\n/, $text, -1 }

sub _block_of {
  my ( $lines ) = @_;
  my ( $begin, $end ) = ( -1, -1 );
  for my $i ( 0 .. $#$lines ) {
    $begin = $i if $begin == -1 && $lines->[$i] eq BEGIN_LINE;
    $end   = $i if $end == -1   && $lines->[$i] eq END_LINE;
  }
  return ( $begin, $end, ( $begin != -1 && $end != -1 && $end > $begin ) ? 1 : 0 );
}

sub block_entries {
  my ( $path ) = @_;
  my @lines = eval { _lines( read_text($path) ) } or return ();
  my ( $begin, $end, $has ) = _block_of( \@lines );
  return $has ? @lines[ $begin + 1 .. $end - 1 ] : ();
}

sub has_block {
  my ( $dir ) = @_;
  my @lines = eval { _lines( read_text( path_join( $dir, '.gitignore' ) ) ) } or return 0;
  return ( _block_of( \@lines ) )[2];
}

sub _trim_trailing_empty {
  my ( @lines ) = @_;
  pop @lines while @lines && js_blank( $lines[-1] );
  return @lines;
}

sub _update_block_file {
  my ( $path, %opts ) = @_;
  my $bytes    = encode_text($path);
  my $existed  = -e $bytes;
  my $existing = $existed ? read_text($path) : '';
  my @lines    = length $existing ? _lines($existing) : ();
  my ( $begin, $end, $has ) = _block_of( \@lines );
  my @outside = $has ? ( @lines[ 0 .. $begin - 1 ], @lines[ $end + 1 .. $#lines ] ) : @lines;

  my %seen;
  my @entries = js_sort_keys( grep { !$seen{$_}++ } @{ $opts{entries} } );
  my $write = $opts{enabled} && @entries;
  my ( @out, $change );
  if ($write) {
    my @block = ( BEGIN_LINE, @entries, END_LINE );
    if ($has) {
      @out = ( @lines[ 0 .. $begin - 1 ], @block, @lines[ $end + 1 .. $#lines ] );
      $change = join( "\n", @lines[ $begin + 1 .. $end - 1 ] ) eq join( "\n", @entries ) ? 'unchanged' : 'changed';
    }
    else {
      my @trimmed = _trim_trailing_empty(@outside);
      @out = @trimmed ? ( @trimmed, '', @block ) : @block;
      $change = 'created';
    }
  }
  else {
    @out = _trim_trailing_empty(@outside);
    $change = $has ? 'removed' : 'unchanged';
  }

  my $result = ( @out && grep { !js_blank($_) } @out ) ? ( join( "\n", @out ) =~ s/\n*\z//r )."\n" : '';
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

version 0.001

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

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
