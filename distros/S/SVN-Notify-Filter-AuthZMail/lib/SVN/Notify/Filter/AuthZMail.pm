package SVN::Notify::Filter::AuthZMail;


# $Id: AuthZMail.pm 19 2008-07-17 06:14:46Z jborlik $

use warnings;
use strict;
use SVN::Notify;
use SVN::Access;
use File::Basename;
use Carp;

=head1 NAME

SVN::Notify::Filter::AuthZMail - Determines Subversion accounts to receive the email, via the AuthZSVNAccess file

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

my $acl;          # Access control list, via SVN::Access
my $debugflag=0;  # 1=debug output, not for general use

SVN::Notify->register_attributes(
                                 authz_file  => 'authz_file=s',
                                 authz_module => 'authz_module=s',
                                );

=head1 SYNOPSIS

This is intended to work with SVN::Notify, as part of a subversion post-commit hook.

    svnnotify --repos-path "$1" --revision "$2" ..etc..  \
              --filter AuthZMail                         \
                    --authz_file /x/x/x/authz            \
                    --authz_module yyy


=head1 DESCRIPTION

This module is a filter for SVN::Notify, intended to assist with the maintenance of
access control lists with Subversion repositories.  This module removes the need to
maintain a separate list of people to send email notification messages to (via
svnnotify --to arguments), from the AuthZSVNAccessFile.

Based upon the Subversion revision, it finds the files that were modified in the
commit, determines the union of people that access to those files (via the AuthZ
file), and passes those account names into the SVN::Notify.  Hopefully, this module
follows Subversion's rules for determining access.

This module works well with SVN::Notify::Filter::EmailFlatFileDB.  If this filter
is put first in the svnnotify argument list, it will add to the usernames to
SVN::Notify's list of recipient names, and then the EmailFlatFileDB filter will
convert those usernames into email addresses.

(Note that for SVN::Notify versions less than 2.76, you may need to include a
--to option line in order to bypass some of SVN::Notify's checking.)


=head1 DEPENDENCIES

This module depends upon SVN::Notify, by David Wheeler.  It also depends upon
SVN::Access, by Michael Gregorowicz, to parse the AuthZ file.



=head1 FUNCTIONS

=head2 from

This SVN::Notify callback function is not used.

=cut

#  SVN::Notify filter callback function for --from
# The first argument is the SVN::Notify object
# The second argument is the sender address, passed in
# as the committer account name.
sub from {
  my ($notifier, $from) = @_;

  if ($debugflag) { print "AuthZEmail  from=$from\n"; }

  return $from;
}


=head2 pre_prepare

This SVN::Notify callback function adds the usernames to the list,
based on the contents of the authz file.  This is executed
automatically by the SVN::Notify framework.  It will add to the
list of recipients.  Note that any other SVN::Notify::Filter
that manipulates the list of recipients should be specified
after this filter.

=cut

#  SVN::Notify filter callback function for --to
# The first argument is the SVN::Notify object
# The second argument is an array reference to the
# recipient email addresses.

#  This will add usernames to the list, based on
#  the contents of the authz file.

sub pre_prepare {
  my ($notifier) = @_;

  my @recip = $notifier->to;
  
  my @files;
  my $svnrev = $notifier->revision;
  my $svnlook = $notifier->svnlook;
  my $path_to_repo = $notifier->repos_path;
  my $authz_module = $notifier->authz_module;
  my $authz_file = $notifier->authz_file;

  # initialize the AuthZ file reader
  $acl = SVN::Access->new(acl_file => $authz_file);

  
  if ($svnrev > 0) {
    # add additional files to the list by parsing the output of svnlook
    # for the given rev number
    my $cmd = "$svnlook changed $path_to_repo -r $svnrev";
    open (SVNIN, "$cmd |") or croak "SVN::Notify::Filter::AuthZMail can't open svnlook while doing 'to' list: $cmd";

    while (<SVNIN>) {
      chomp;
      /^\w+\s+(.+)/;
      push(@files,$1);

    }

    close SVNIN;
  }

  if ($debugflag) { print 'AuthZMail numfiles=' . $#files . ': ' . join('|', @files) . "\n"; }

  # Now process the files.  Note that we will not clear out the hash,
  # so it will be the union of all users that have access to any file.
  my %users = ();
  for my $thisfile (@files) {
    _listUsersThatCanAccessFile($authz_module,$thisfile,\%users);
  }
  if ($debugflag) { _writePerms("all files", \%users); }

  push @recip, keys(%users);

  $notifier->to(@recip);
}



=head1 AUTHOR

Jeffrey Borlik, C<< <jborlik at earthlink.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-svn-notify-filter-authzmail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Notify-Filter-AuthZMail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVN::Notify::Filter::AuthZMail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN-Notify-Filter-AuthZMail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVN-Notify-Filter-AuthZMail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVN-Notify-Filter-AuthZMail>

=item * Search CPAN

L<http://search.cpan.org/dist/SVN-Notify-Filter-AuthZMail>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to David Wheeler for his SVN::Notify Perl module.  Also, thanks to Michael Gregorowicz
for SVN::Access.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Jeffrey Borlik, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


#----------------------------------------------------------


# This function will return a hash of users and permissions,
# for a given file in the SVN authz file.
#
# Note that it requires a global variable $acl, and
# arguments of the repository name and filename

sub _listUsersThatCanAccessFile {

  my ($repos,$file,$users) = @_;

  # keys are the usernames, values are the permissions (r, rw)

  my ($file_name, $file_path, $file_suff) = fileparse($file);
  $file_path = '/' . $file_path;


  # First, develop a list of "resources" that apply to this file.
  my @applic_res = ();

  #iterate through all possible paths
  # (Another option would be to iterate through all known resources)
  my @allpaths = split('/',$file_path);
  #print '>' . join('|',@allpaths) . "<\n";

  for (@allpaths) {
    # All repositories
    my $gotit = $acl->resource('/' . $_);
    if ($gotit) {
      push(@applic_res, $gotit);
    }
    # Specified repository
    $gotit = $acl->resource($repos . ':/' . $_);
    if ($gotit) {
      push(@applic_res, $gotit);
    }
  }

  # Sort them
  @applic_res = sort { $b->name cmp $a->name } @applic_res;
  #print "Sorted applicable resources:\n";
  #for (@applic_res) { print $_->name . '|'; }
  #print "\n";

  # Now, iterate through the list, adding users/rights to the map.
  # Groups are immediately "expanded".
  # The longest resources are the "most local", so apply them first
  # Subsequent user entries will be ignored.  This is what the
  # SVN Red Book says:  Most-specific path wins, and within the
  # each path, the highest user listing.

  foreach my $this_res (@applic_res) {
    while (my ($user, $perms) = each(%{$this_res->authorized})) {
      if ($user eq '*') {
        # anonymous access... we will just ignore this
      } elsif (substr($user,0,1) eq '@') {
        # group
        my $groupname = substr($user,1);
        my $res_group = $acl->group($groupname);
        if (not $res_group) {
          print "Can't find group $groupname!!\n";
        } else {
          # iterate through all of the group members
          foreach my $member ($res_group->members) {
            if (not exists $$users{$member}) {
              $$users{$member} = $perms;
#              print "Adding user (group member): $member\n";
            }
          }
        }
      } else {
        # Non-group was specified
        if (not exists $$users{$user}) {
          $$users{$user} = $perms;
#          print "Adding user: $user\n";
        }
      }
    }
  }

  # Next, we will remove users that do not have valid permissions
  foreach my $this_user (keys(%$users)) {
    if ($$users{$this_user} eq '') {
      delete $$users{$this_user};
    }
  }

}


#----------------------------------------------------------
# Write-out routines, for debugging/testing

sub _writePerms {
  my $testfile = shift;
  my %users = %{shift(@_)};
  
  print "AuthZMail for $testfile.........\n";
  for my $user (keys(%users)) {
    print "  $user = " . $users{$user} . "\n";
  }
}


1; # End of SVN::Notify::Filter::AuthZMail
