package SVN::Notify::Filter::EmailFlatFileDB;

use warnings;
use strict;
use SVN::Notify;
use Carp;


=head1 NAME

SVN::Notify::Filter::EmailFlatFileDB - Converts account names to email address based on a flat-file database

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

SVN::Notify->register_attributes(
                                 account_file  => 'account_file=s',
                                 account_field => 'account_field=i',


                                 );

my %allusers;  # key=account name, value=array reference to fields from the file
my $SPLITCHAR = ':';
my $debug = 0;

=head1 SYNOPSIS

This is intended to work with SVN::Notify, as part of a subversion post-commit hook.

    svnnotify --repos-path "$1" --revision "$2" ..etc..  \
              --filter EmailFlatFileDB                   \
                    --account_file /x/x/x/users.db         \
                    --account_field 3

    with a text file like other UNIX/Apache password files:

       user1:xxx:xxx:user1@example.com
       user2:xxx:xxx:user2@example.com

=head1 DESCRIPTION

This module is a filter for SVN::Notify, which will translate
user account names (e.g. "user1") into email address.  It does
this based on a colon-separated file, like a UNIX passwd file
(or more usefully) the AuthUserFile used by Apache.  The file
path is specified via the --account_file option to the svnnotify
script, and the index (zero-based) of the email field is specified via the
--account_field option.

You can use the module in conjunction with SVN::Notify::Filter::AuthZEmail
to completely remove the necessity of passing in --from and --to options
to the script.  (AuthZEmail will determine the account names for the
email recipients, and this module will translate the account names into
email addresses.)

(This module will remove --to entries that are empty.)


=head1 FUNCTIONS

=head2 from

SVN::Notify filter callback function for the "from" email address.
By default, SVN::Notify uses the account name of the commit author.
This will translate that into the email address, based upon the
value in the database file.  Note that the svnnotify --from option
can also be used to override the default SVN::Notify behavior, and
this filter will not modify an email address if it is passed in.

=cut

# The first argument is the SVN::Notify object
# The second argument is the sender account name or address.

sub from {
  my ($notifier, $from) = @_;
  my $dbfield= $notifier->account_field;

  if ($debug) { print "EmailFlatFileDB From: $from ($dbfield)"; }

  # load database... I'm not sure if the order of from/to
  # is always going to be fixed
  if (! %allusers) {
    my $dbfile = $notifier->account_file;
    _loadPasswdDb($dbfile,\%allusers,$dbfield);
    if ($debug) { _writePasswdDb(\%allusers); }
  }

  ($from) = _translateEmails(\%allusers,$dbfield,$from);
  if ($debug) { print " translated to: $from\n"; }

  return $from;
}

=head2 recipients

SVN::Notify filter callback function to determine the email
addresses for the email recipients, based upon account names
passed to SVN::Notify.

Account names will be looked up via the flat-file database, but
any email addresses passed in will not be modified.  This allows
one to enter either account names or email address via the svnnotify
--to options.  Email addresses are distinguished from account names
if there is an '@' in the string.  Empty string account names will
be discarded.  (The SVN::Notify object requires a --to argument,
and an empty string account name is a workaround for that, for
filters that completely provide the recipient list.)

=cut


# The first argument is the SVN::Notify object
# The second argument is an array reference to the recipients.
sub recipients {
  my ($notifier, $recip) = @_;

  my $dbfield= $notifier->account_field;

  if ($debug) { print 'EmailFlatFileDB to: ' . join(',',@$recip) . "\n"; }

  # if the file hasn't been loaded yet, do so
  if (! %allusers) {
    my $dbfile = $notifier->account_file;
    _loadPasswdDb($dbfile,\%allusers,$dbfield);
    if ($debug) { _writePasswdDb(\%allusers); }
  }

  @$recip = _translateEmails(\%allusers,$dbfield,@$recip);

  return $recip;
}

=head1 AUTHOR

Jeffrey Borlik, C<< <jborlik at earthlink.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-svn-notify-filter-emailflatfiledb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Notify-Filter-EmailFlatFileDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVN::Notify::Filter::EmailFlatFileDB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN-Notify-Filter-EmailFlatFileDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVN-Notify-Filter-EmailFlatFileDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVN-Notify-Filter-EmailFlatFileDB>

=item * Search CPAN

L<http://search.cpan.org/dist/SVN-Notify-Filter-EmailFlatFileDB>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to David E. Wheeler for SVN::Notify, a very useful tool for Subversion.


=head1 COPYRIGHT & LICENSE

Copyright 2008 Jeffrey Borlik, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


#################################################################
#
# Helper functions
#

sub _loadPasswdDb {
  my $passwd_file = shift;
  my $db = shift; # this is a hash (key=username, val=array [user fields])
  my $maxfields = shift; # number of fields needed to store

  open (INFILE, $passwd_file) or croak "Can't open email/account file $passwd_file: $!";

  while (<INFILE>) {
    chomp;
    if (/^\w*$/) { next; } # all whitespace
    if (/^\w*#/) { next; } # hash is a comment

    my @line = split($SPLITCHAR);
    $#line = $maxfields; # Only keep the number of fields needed
    $$db{lc(shift(@line))} = \@line;
  }

  close INFILE;
}

sub _writePasswdDb {
  my %db = %{shift(@_)};

  print "EmailFlatFileDB: Users in DB......\n";
  for my $user (keys(%db)) {
    my $attrs = $db{$user};
    print "  $user: " . join('|',@$attrs) . "\n";
  }
}

# Uses the hash of user information to return a list of
# email addresses, given a list of usernames.  Note that the
# two arrays are not necessarily of the same size, as users
# that are not in the db are dropped.

sub _translateEmails {
  my $allusers = shift; # users hash
  my $emailfield = shift; # index of the email field
  # the rest of the arguments are the actual users

  my @emails = ();

  for my $thisuser (@_) {
    $thisuser = lc($thisuser);
    if (length($thisuser)==0) {
        # no accountname
        next;
    }
    if ($thisuser =~ /@/) {
      if ($debug >=2) { print "EmailFlatFileDB: $thisuser is already an email address\n"; }
      push(@emails,$thisuser);
      next;
    }
    if (exists($$allusers{$thisuser})) {
      if ($debug >= 2) { print "EmailFlatFileDB: found $thisuser / " . $$allusers{$thisuser}[$emailfield-1]; }
      push(@emails, $$allusers{$thisuser}[$emailfield-1]);
    } else {
      if ($debug) { print "Skipping $thisuser as there is no email record for them.\n"; }
    }
  }

  return @emails;
}

1; # End of SVN::Notify::Filter::EmailFlatFileDB
