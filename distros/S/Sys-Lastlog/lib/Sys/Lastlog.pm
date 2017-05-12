#*****************************************************************************
#*                                                                           *
#*                          Gellyfish Software                               *
#*                                                                           *
#*                                                                           *
#*****************************************************************************
#*                                                                           *
#*      PROGRAM     :  Sys::Lastlog                                          *
#*                                                                           *
#*      AUTHOR      :  JNS                                                   *
#*                                                                           *
#*      DESCRIPTION :  Provide Object(ish) Interface to lastlog files        *
#*                                                                           *
#*                                                                           *
#*****************************************************************************
#*                                                                           *
#*      $Id$ 
#*                                                                           *
#*****************************************************************************

package Sys::Lastlog;

=head1 NAME

Sys::Lastlog - Provide a moderately Object Oriented Interface to lastlog 
               files on some Unix-like systems.

=head1 SYNOPSIS

  use Sys::Lastlog;

  my $ll = Sys::Lastlog->new();

  while(my $llent = $ll->getllent() )
  {
    print $llent->ll_line(),"\n";
  }

=head1 DESCRIPTION

The lastlog file provided on most Unix-like systems stores information about
when each user on the system last logged in.  The file is sequential and
indexed on the UID (that is to say a user with UID 500 will have the 500th
record in the file).  Most systems do not provide a C API to access this
file and programs such as 'lastlog' will provide their own methods of doing
this.

This module provides an Object Oriented Perl API to access this file in order
that programs like 'lastlog' can written in Perl (for example the 'plastlog'
program in this distribution) or that programs can determine a users last
login for their own purposes.

The module provides three methods for accessing lastlog sequentially, by
UID or by login name.  Each method returns an object of type Sys::Lastlog::Entry
 that itself provides methods for accessing the information for each record.

=head2 METHODS

=over 4

=item new

The constructor of the class.  Returns a blessed object that the other methods
can be called on.

=item lastlog_path

Returns the full path to the lcoation of the lastlog file as defined by the
operating system. Possibly only useful for diagnostic purposes currently.

=item getllent

This method will sequentially return each record in the lastlog each time it
is called, returning a false value when there are no more records to return.
Because the lastlog file is indexed on UID if there are gaps in the allocation
of UIDs on a system will there will be as many empty records returned ( that
is to say if for some reason there are no UIDs used between 200 and 500 this
method will nonetheless return the 299 empty records .)  

=item getlluid SCALAR $uid

This method will return a record for the $uid specified or a false value if
the UID is out of range, it does however perform no check that the UID has
actually been assigned it must simply be less than or equal to the maximum
UID currently assigned on the system.

=item getllnam SCALAR $logname

This will return the record corresponding to the user name $logname or
false if it is not a valid user name.  

=item setllent

Set the file pointer on the lastlog file back to the beginning of the file
for repeated iteration over the file using getllent() .

=back

=head2 PER RECORD METHODS

These are the methods of the class Sys::Lastlog::Entry that give access to
the information for each record.

=over 4

=item uid

The UID that corresponds to this record.

=item ll_time

The time in epoch seconds of this users last login.

=item ll_line

The line (e.g. terminal ) that this user logged in via.

=item ll_host

The host from which this user logged in from or the empty string if it was
a local login.

=back

=cut

use strict;

require DynaLoader;

use vars qw(
            @ISA
            $VERSION
            $AUTOLOAD
           );

@ISA = qw(
          DynaLoader
         );

$VERSION = '1.7';

bootstrap Sys::Lastlog $VERSION;

sub new
{
  my ( $proto, $args ) = @_;

  my $class = ref($proto) || $proto;

  my $self = {};

  bless $self, $class;

  return $self;
}

1;

package Sys::Lastlog::Entry;

use Carp;
use vars qw(
            $AUTOLOAD
           );

sub AUTOLOAD
{
  my ( $self ) = @_;

  no strict 'refs';

  ( my $methname = $AUTOLOAD ) =~ s/.*:://;

  if ( exists $self->{$methname} )
  {
    *{$AUTOLOAD} = sub {
                         my ( $self ) = @_;
                         return $self->{$methname};
                        };
  }
  else
  {
    croak "Method $methname is not defined";
  }

  goto &{$AUTOLOAD};

}

1;
__END__

=head2 EXPORT

None at all

=head1 BUGS

Probably.

Some systems (notoriously Red Hat Linux) may mistakenly rotate the lastlog
file periodically - there is no benefit in doing this as the file will only
grow if new users are added to the system and in the authors opinion it
is important to keep an accurate record of all users last logins however
long ago for audit and security purposes. If you are on such a system and
care about this you should disable the rotation of this file. On a Red Hat
system this will involve editing /etc/logrotate.conf to remove the file
from the rotation.

This should build on most systems given the notes in README but the author
would appreciate being informed of any unusual systems where difficulty
may be experienced.

The code is hosted at https://github.com/jonathanstowe/Sys-Lastlog so do
feel free to fork and send pull requests

Occasionaly you may find that the entries in your /etc/passwd are out of
order and this may give rise to test failures or other problems.  You can
either run setllent() if you find a missing entry or reorder your passwd
file numerically.  You may also need to reset the lastlog file by truncating
the file and then logging in as the user with the highest UID.

You also almost certainly want to *not* try and get a lastlog entry for the
user 'nobody' as this conventionally has a uid of 65534 and the lastlog file
doesn't get that big.

It would probably be useful to set the path to the lastlog file from
within the perl program. This is on the TODO list.

=head1 AUTHOR

Jonathan Stowe E<lt>jns@gellyfish.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright Jonathan Stowe 2001 - 2013.

This software comes with no warranty whatsoever.

This is free software and may be distributed and/or modified under the
same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=cut
