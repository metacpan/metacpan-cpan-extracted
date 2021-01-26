use v5.10;

package Module::Release::Git;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT = qw(
	check_vcs vcs_tag vcs_exit make_vcs_tag get_vcs_tag_format
	get_recent_contributors
	);

our $VERSION = '1.015';

=encoding utf8

=head1 NAME

Module::Release::Git - Use Git with Module::Release

=head1 SYNOPSIS

The release script automatically loads this module if it sees a
F<.git> directory. The module exports C<check_vcs>, C<vcs_tag>, and
C<make_vcs_tag>.

=head1 DESCRIPTION

Module::Release::Git subclasses Module::Release, and provides
its own implementations of the C<check_vcs()> and C<vcs_tag()> methods
that are suitable for use with a Git repository.

These methods are B<automatically> exported in to the callers namespace
using Exporter.

This module depends on the external git binary (so far).

=over 4

=item check_vcs()

Check the state of the Git repository.

=cut

sub check_vcs {
	my $self = shift;

	$self->_print( "Checking state of Git... " );

	my $git_status = $self->run('git status -s 2>&1');

	no warnings 'uninitialized';

	my( $branch ) = $self->run('git rev-parse --abbrev-ref HEAD');

	my $up_to_date = ($git_status eq '');

	$self->_die( "\nERROR: Git is not up-to-date: Can't release files\n\n$git_status\n" )
		unless $up_to_date;

	$self->_print( "Git up-to-date on branch $branch\n" );

	return 1;
	}

=item vcs_tag(TAG)

Tag the release in local Git.

=cut

sub vcs_tag {
	my( $self, $tag ) = @_;

	$tag ||= $self->make_vcs_tag;

	$self->_print( "Tagging release with $tag\n" );

	return 0 unless defined $tag;

	$self->run( "git tag $tag" );

	return 1;
	}

=item make_vcs_tag

By default, examines the name of the remote file
(i.e. F<Foo-Bar-0.04.tar.gz>) and constructs a tag string like
C<release-0.04> from it.  Override this method if you want to use a
different tagging scheme, or don't even call it.

=cut

sub make_vcs_tag {
	my( $self, $tag_format ) = @_;
	$tag_format = defined $tag_format ? $tag_format : $self->get_vcs_tag_format;

	my $version = eval { $self->dist_version };
	my $err = $@;
	unless( defined $version ) {
		$self->_warn( "Could not get version [$err]" );
		$version = $self->_get_time;
		}

	$tag_format =~ s/%v/$version/e;

	return $tag_format;
	}

sub _get_time {
	my( $self ) = @_;
	require POSIX;
	POSIX::strftime( '%Y%m%d%H%M%S', localtime );
	}

=item get_vcs_tag_format

Return the tag format. It's a sprintf-like syntax, but with one format:

	%v  replace with the full version

If you've set C<> in the configuration, it uses that. Otherwise it
returns C<release-%v>.

=cut

sub get_vcs_tag_format {
	my( $self ) = @_;

	$self->config->get( 'git_default_tag' ) ||
	'release-%v'
	}

=item vcs_exit

Perform repo tasks post-release. This one pushes origin to master
and pushes tags.

=cut

sub vcs_exit {
	my( $self, $tag ) = @_;

	$tag ||= $self->make_vcs_tag;

	$self->_print( "Cleaning up git\n" );

	return 0 unless defined $tag;

	$self->_print( "Pushing to origin\n" );
	$self->run( "git push origin master" );

	$self->_print( "Pushing tags\n" );
	$self->run( "git push --tags" );

	return 1;
	}

=item get_recent_contributors()

Return a list of contributors since last release.

=cut

sub get_recent_contributors {
	my $self = shift;

	chomp( my $last_tagged_commit    = $self->run("git rev-list --tags --max-count=1") );
	chomp( my @commits_from_last_tag = split /\R/, $self->run("git rev-list $last_tagged_commit..HEAD") );

	my @authors_since_last_tag =
		map { qx{git show --no-patch --pretty=format:'%an <%ae>' $_} }
		@commits_from_last_tag;
	my %authors = map { $_, 1 } @authors_since_last_tag;
	my @authors = sort keys %authors;

	return @authors;
	}

=back

=head1 TO DO

=over 4

=item Use Gitlib.pm whenever it exists

=item More options for tagging

=back

=head1 SEE ALSO

L<Module::Release::Subversion>, L<Module::Release>

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/module-release-git

=head1 AUTHOR

brian d foy, <bdfoy@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the same terms as the Artistic License 2.0.

=cut

1;
