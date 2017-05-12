package Module::Install::GithubMeta;

use strict;
use warnings;
use Cwd;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.30';

sub githubmeta {
  my $self = shift;
  return unless $Module::Install::AUTHOR;
  return unless _under_git();
  return unless $self->can_run('git');
  my $remote = shift || 'origin';
  local $ENV{LC_ALL}='C';
  local $ENV{LANG}='C';
  return unless my ($git_url) = `git remote show -n $remote` =~ /URL: (.*)$/m;
  return unless $git_url =~ /github\.com/; # Not a Github repository
  my $http_url = $git_url;
  $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;
  $http_url =~ s![\w\-]+\@([^:]+):!https://$1/!;
  $http_url =~ s!\.git$!/!;
  $self->repository( $git_url );
  $self->homepage( $http_url ) unless $self->homepage();
  return 1;
}

sub _under_git {
  return 1 if -e '.git';
  my $cwd = getcwd;
  my $last = $cwd;
  my $found = 0;
  while (1) {
    chdir '..' or last;
    my $current = getcwd;
    last if $last eq $current;
    $last = $current;
    if ( -e '.git' ) {
       $found = 1;
       last;
    }
  }
  chdir $cwd;
  return $found;
}

'Github';
__END__

=head1 NAME

Module::Install::GithubMeta - A Module::Install extension to include GitHub meta information in META.yml

=head1 SYNOPSIS

  # In Makefile.PL

  use inc::Module::Install;
  githubmeta;

The C<repository> and C<homepage> meta in C<META.yml> will be set accordingly.

=head1 DESCRIPTION

Module::Install::GithubMeta is a L<Module::Install> extension to include GitHub L<http://github.com> meta
information in C<META.yml>.

It automatically detects if the distribution directory is under C<git> version control and whether the
C<origin> is a GitHub repository and will set the C<repository> and C<homepage> meta in C<META.yml> to the
appropriate URLs for GitHub.

=head1 COMMANDS

This plugin adds the following Module::Install command:

=over

=item C<githubmeta>

Does nothing on the user-side. On the author-side it will auto-detect if the directory is under C<git> version control
and whether the C<origin> is a GitHub repository. Will set C<repository> to the public clone URL and C<homepage> to the
http GitHub link for the repository.

You may optionally provide the remote to query, this defaults to C<origin> if not specified.

You may override the C<homepage> setting by using the L<Module::Install> C<homepage> command prior to calling this
command.

  use inc::Module::Install;
  homepage 'http://mymoduleshomepage.com/';
  githubmeta;

=back

=head1 AUTHOR

Chris C<BinGOs> Williams

Based on code from L<Module::Install::Repository> by Tatsuhiko Miyagawa

=head1 LICENSE

Copyright E<copy> Chris Williams and Tatsuhiko Miyagawa

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Module::Install>

=cut
