use v5.16;

package Module::Release::SVN;

use strict;
use warnings;
use Exporter qw(import);

use Carp;

our @EXPORT = qw(check_vcs vcs_tag make_vcs_tag);

our $VERSION = '2.127';

=encoding utf8

=head1 NAME

Module::Release::SVN - Use Subversion with Module::Release

=head1 SYNOPSIS

The release script automatically loads this module if it sees a
F<.svn> directory. The module exports check_cvs, cvs_tag, and make_cvs_tag.

=head1 DESCRIPTION

C<Module::Release::SVN> is a plugin for C<Module::Release>, and provides
its own implementations of the C<check_vcs()> and C<vcs_tag()> methods
that are suitable for use with a Subversion repository rather than a
CVS repository.

These methods are B<automatically> exported in to the callers namespace
using Exporter. You should only use it from C<Module::Release> or its
subclasses.

This module depends on the external svn binary (so far).

=cut

=over 4

=item C<check_cvs()>

DEPRECATED. Use C<check_vcs> now.

=item C<check_vcs()>

Check the state of the SVN repository.

=cut

sub check_cvs {
	carp "check_cvs is deprecated in favor of check_vcs. Update your programs!";
	&check_vcs;
	}

sub check_vcs {
	my $self = shift;

	$self->_print( "Checking state of Subversion..." );

	my $svn_update = $self->run('svn status --show-updates --verbose 2>&1');

	$self->_die(
		sprintf("\nERROR: svn failed with non-zero exit status: %d\n\n"
			. "Aborting release\n", $? >> 8)
		) if $?;

	$svn_update =~ s/^\?\s+/?/;
	$svn_update =~ s/^(........)\s+\d+\s+\d+\s+\S+\s+(.*)$/$1 $2/mg;

	my %message = (
		qr/^C......./m   => 'These files have conflicts',
		qr/^M......./m   => 'These files have not been checked in',
		qr/^........\*/m => 'These files need to be updated',
		qr/^P......./m   => 'These files need to be patched',
		qr/^A......./m   => 'These files were added but not checked in',
		qr/^D......./m   => 'These files are scheduled for deletion',
		qr/^\?......./m  => 'I don\'t know about these files',
		);

	my @svn_states = keys %message;

	my %svn_state;
	foreach my $state (@svn_states) {
		$svn_state{$state} = [ $svn_update =~ /$state\s+(.*)/g ];
		}

	my $count;
	my $question_count;

	foreach my $key ( sort keys %svn_state ) {
		my $list = $svn_state{$key};
		next unless @$list;

		$count          += @$list unless $key eq qr/^\?......./;
		$question_count += @$list if     $key eq qr/^\?......./;

		local $" = "\n\t";
		$self->_print( "\n\t$message{$key}\n", "-" x 50, "\n\t@$list\n" );
		}

	$self->_die( "\nERROR: Subversion is not up-to-date ($count files): Can't release!\n" )
    	if $count;

=pod

	if($question_count)
		{
    	$self->_print "\nWARNING: Subversion is not up-to-date ($question_count files unknown); ",
      "continue anyway? [Ny] " ;
		die "Exiting\n" unless <> =~ /^[yY]/;
		}

=cut

	$self->_print( "Subversion up-to-date\n" );
	}

=item C<cvs_tag()>

DEPRECATED. Use C<vcs_tag> now.

=item C<vcs_tag(TAG)>

Tag the release in Subversion.

=cut


sub cvs_tag {
	carp "cvs_tag is deprecated in favor of vcs_tag. Update your programs!";
	&check_vcs;
	}

sub vcs_tag {
	require URI;

	my $self = shift;

	my $svn_info = $self->run('svn info .');

	if($?)
		{
		$self->_warn(
			sprintf(
				"\nWARNING: 'svn info .' failed with non-zero exit status: %d\n",
				$? >> 8 )
			);

		return;
		}

	$svn_info =~ /^URL: (.*)$/m;
	my $trunk_url = URI->new( $1 );

	my @tag_url = $trunk_url->path_segments;
	if(! grep /^trunk$/, @tag_url ) {
		$self->_warn(
			"\nWARNING: Current SVN URL:\n  $trunk_url\ndoes not contain a 'trunk' component\n",
			"Aborting tagging.\n"
			);

		return;
		}

	foreach( @tag_url ) {
		if($_ eq 'trunk') {
			$_ = 'tags';
			last;
			}
		}

	my $tag_url = $trunk_url->clone;

	$tag_url->path_segments( @tag_url );

	# Make sure the top-level path exists
	#
	# Can't use $self->run() because of a bug where $fh isn't closed, which
	# stops $? from being properly propagated.  Reported to brian d foy as
	# part of RT#6489
	$self->run( "svn list $tag_url 2>&1" );
	if( $? ) {
		$self->_warn(
			sprintf("\nWARNING:\n  svn list $tag_url\nfailed with non-zero exit status: %d\n", $? >> 8),
			"Assuming tagging directory does not exist in repo.  Please create it.\n",
			"Aborting tagging.\n"
			);

		return;
		}

	my $tag = $self->make_vcs_tag;

	push @tag_url, $tag;
	$tag_url->path_segments(@tag_url);
	$self->_print( "Tagging release to $tag_url\n" );

	$self->run( "svn copy $trunk_url $tag_url" );

	if ( $? ) {
		# already uploaded, and tagging is not (?) essential, so warn, don't die
		$self->_warn(
			sprintf(
				"\nWARNING: svn failed with non-zero exit status: %d\n",
				$? >> 8 )
			);
		}

	}

=item C<make_cvs_tag()>

DEPRECATED. Use C<make_vcs_tag> now.

=item make_vcs_tag

By default, examines the name of the remote file
(i.e. F<Foo-Bar-0.04.tar.gz>) and constructs a tag string like
C<RELEASE_0_04> from it.  Override this method if you want to use a
different tagging scheme, or don't even call it.

=cut


sub make_cvs_tag {
	carp "make_cvs_tag is deprecated in favor of make_vcs_tag. Update your programs!";
	&make_vcs_tag;
	}

sub make_vcs_tag {
	my $self = shift;
	my( $major, $minor ) = $self->remote_file
		=~ /(\d+) \. (\d+(?:_\d+)?) (?:\. tar \. gz)? $/xg;

	return "RELEASE_${major}_${minor}";
	}

sub vcs_exit { 1 }

=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is in GitHub

	https://github.com/briandfoy/module-release

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2021, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=cut

1;
