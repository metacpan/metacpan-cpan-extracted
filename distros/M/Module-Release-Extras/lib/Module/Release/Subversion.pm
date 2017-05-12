package Module::Release::Subversion;

use strict;
use warnings;
use base qw(Exporter Module::Release);

our @EXPORT = qw(check_cvs cvs_tag);

use URI;			# svn URL mangling

our $VERSION = '0.10';

=head1 NAME

Module::Release::Subversion - Use Subversion instead of CVS with Module::Release

=head1 SYNOPSIS

In F<.releaserc>

  release_subclass Module::Release::Subversion

In your subclasses of Module::Release:

  use base qw(Module::Release::Subversion);

=head1 DESCRIPTION

Module::Release::Subversion subclasses Module::Release, and provides
its own implementations of the C<check_cvs()> and C<cvs_tag()> methods
that are suitable for use with a Subversion repository rather than a
CVS repository.

These methods are B<automatically> exported in to the callers namespace
using Exporter.

=cut

=head2 C<check_cvs()>

Check the state of the Subversion repository.

=cut

sub check_cvs {
  my $self = shift;

  print "Checking state of Subversion... ";

  my $svn_update = $self->run('svn status --show-updates --verbose 2>&1');

  if($?) {
    die sprintf("\nERROR: svn failed with non-zero exit status: %d\n\n"
		. "Aborting release\n", $? >> 8);
  }

  # Trim $svn_update a bit to make the regex later a little simpler
  $svn_update =~ s/^\?\s+/?/;	# Collapse spaces after /^?/
  # Remove the revision number and author columns
  $svn_update =~ s/^(........)\s+\d+\s+\d+\s+\S+\s+(.*)$/$1 $2/mg;

  my %message = (
		 qr/^C......./   => 'These files have conflicts',
		 qr/^M......./   => 'These files have not been checked in',
		 qr/^........\*/ => 'These files need to be updated',
		 qr/^P......./   => 'These files need to be patched',
		 qr/^A......./   => 'These files were added but not checked in',
		 qr/^D......./   => 'These files are scheduled for deletion',
		 qr/^\?......./  => 'I don\'t know about these files',
		   );

  my @svn_states = keys %message;

  my %svn_state;
  foreach my $state (@svn_states) {
    $svn_state{$state} = [ $svn_update =~ /$state\s+(.*)/gm ];

  }

  my $rule = "-" x 50;
  my $count;
  my $question_count;

  foreach my $key (sort keys %svn_state) {
    my $list = $svn_state{$key};
    next unless @$list;
    $count += @$list unless $key eq qr/^\?......./;
    $question_count += @$list if $key eq qr/^\?......./;

    local $" = "\n\t";
    print "\n\t$message{$key}\n\t$rule\n\t@$list\n";
  }

  die "\nERROR: Subversion is not up-to-date ($count files): Can't release files\n"
    if $count;

  if($question_count) {
    print "\nWARNING: Subversion is not up-to-date ($question_count files unknown); ",
      "continue anwyay? [Ny] " ;
    die "Exiting\n" unless <> =~ /^[yY]/;
  }

  print "Subversion up-to-date\n";
} # check_cvs

=head2 C<cvs_tag()>

Tag the release in local Subversion.

The approach is fairly simple.  C<svn info> is run to extract the
Subversion URL for the current directory, and the first occurence of
'/trunk/' in the URL is replaced with '/tags/'.  We check that the new URL
exists, and then C<svn copy> is used to do the tagging.

Failures are non fatal, since the upload has already happened.

=cut

sub cvs_tag {
  my $self = shift;

  my $svn_info = $self->run('svn info .');
  if($?) {
    warn sprintf("\nWARNING: 'svn info .' failed with non-zero exit status: %d\n", $? >> 8);
    return;
  }

  $svn_info =~ /^URL: (.*)$/m;
  my $trunk_url = URI->new($1);

  my @tag_url = $trunk_url->path_segments();
  if(! grep /^trunk$/, @tag_url) {
    warn "\nWARNING: Current SVN URL:\n  $trunk_url\ndoes not contain a 'trunk' component\n";
    warn "Aborting tagging.\n";
    return;
  }

  foreach (@tag_url) {		# Find the first 'trunk' component, and
    if($_ eq 'trunk') {		# change it to 'tags'
      $_ = 'tags';
      last;
    }
  }

  my $tag_url = $trunk_url->clone();

  $tag_url->path_segments(@tag_url);

  # Make sure the top-level path exists
  #
  # Can't use $self->run() because of a bug where $fh isn't closed, which
  # stops $? from being properly propogated.  Reported to brian d foy as
  # part of RT#6489
  system "svn list $tag_url 2>&1";
  if($?) {
    warn sprintf("\nWARNING:\n  svn list $tag_url\nfailed with non-zero exit status: %d\n", $? >> 8);
    warn "Assuming tagging directory does not exist in repo.  Please create it.\n";
    warn "\nAborting tagging.\n";
    return;
  }

  my $tag = $self->make_cvs_tag;
  push @tag_url, $tag;
  $tag_url->path_segments(@tag_url);
  print "Tagging release to $tag_url\n";

  system 'svn', 'copy', $trunk_url, $tag_url;

  if ( $? ) {
    # already uploaded, and tagging is not (?) essential, so warn, don't die
    warn sprintf(
		 "\nWARNING: cvs failed with non-zero exit status: %d\n",
		 $? >> 8
		);
  }

} # cvs_tag

=head1 AUTHOR

Nik Clayton <nik@FreeBSD.org>

Copyright 2004 Nik Clayton.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module::Release::Extras>.


=head1 SEE ALSO

Module::Release

=cut

1;
