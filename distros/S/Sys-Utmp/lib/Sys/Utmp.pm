#*****************************************************************************
#*                                                                           *
#*                            Gellyfish Software                             *
#*                                                                           *
#*                                                                           *
#*****************************************************************************
#*                                                                           *
#*      MODULE      :  Sys::Utmp                                             *
#*                                                                           *
#*      AUTHOR      :  JNS                                                   *
#*                                                                           *
#*      DESCRIPTION :  Object(ish) interface to utmp information             *
#*                                                                           *
#*                                                                           *
#*****************************************************************************

package Sys::Utmp;

=head1 NAME

Sys::Utmp - Object(ish) Interface to UTMP files.

=head1 SYNOPSIS

  use Sys::Utmp;

  my $utmp = Sys::Utmp->new();

  while ( my $utent =  $utmp->getutent() )
  {
     if ( $utent->user_process )
     {
        print $utent->ut_user,"\n";
     }
   }

   $utmp->endutent;

See also examples/pwho in the distribution directory.

=head1 DESCRIPTION

Sys::Utmp provides a vaguely object oriented interface to the Unix user
accounting file ( sometimes /etc/utmp or /var/run/utmp).  Whilst it would
prefer to use the getutent() function from the systems C libraries it
will attempt to provide its own if they are missing.

This may not be the module that you are looking for - there is a User::Utmp
which provides a different procedural interface and may well be more complete
for your purposes.

=head2 METHODS

=over 4

=item new

The constructor of the class.  Arguments may be provided in Key => Value
pairs : it currently takes one argument 'Filename' which will set the file
which is to be used in place of that defined in _PATH_UTMP.

=item getutent

Iterates of the records in the utmp file returning a Sys::Utmp::Utent object
for each record in turn - the methods that are available on these objects
are descrived in the L<Sys::Utmp::Utent> documentation.  If called in a list
context it will return a list containing the elements of th Utent entry 
rather than an object.  If the import flag ':fields' is used then constants
defining the indexes into this list will be defined, these are uppercase
versions of the methods described in L<Sys::Utmp::Utent>.

=item setutent

Rewinds the file pointer on the utmp filehandle so repeated searches can be
done.

=item endutent

Closes the file handle on the utmp file.

=item utmpname SCALAR filename

Sets the file that will be used in place of that defined in _PATH_UTMP.
It is not defined what will happen if this is done between two calls to
getutent() - it is recommended that endutent() is called first.

=back

=cut

use strict;
use Carp;

require Exporter;
require DynaLoader;

use vars qw(
            @ISA
            %EXPORT_TAGS
            @EXPORT_OK
            @EXPORT
            $VERSION
            $AUTOLOAD
            @constants
           );

@ISA = qw(Exporter DynaLoader);

BEGIN
{
   @constants = qw(
                   ACCOUNTING
                   BOOT_TIME
                   DEAD_PROCESS
                   EMPTY
                   INIT_PROCESS
                   LOGIN_PROCESS
                   NEW_TIME
                   OLD_TIME
                   RUN_LVL
                   USER_PROCESS
                  );
}
use Sys::Utmp::Utent;

BEGIN
{
   %EXPORT_TAGS = (  
                    'constants' => [ @constants ],
                    'fields'    => [ @Sys::Utmp::Utent::EXPORT]
                  );

   @EXPORT_OK = ( @{ $EXPORT_TAGS{'constants'} }, @{ $EXPORT_TAGS{'fields'}} );
}

$VERSION = '1.7';

sub new 
{
  my ( $proto, %args ) = @_;

  my $self = {};

  my $class = ref($proto) || $proto;

  bless $self, $class;

  if ( exists $args{Filename} and -s $args{Filename} )
  {
    $self->utmpname($args{Filename});
  }
  
  return $self;
}


sub AUTOLOAD 
{
    my ( $self ) = @_;

    my $constname;
    return if $AUTOLOAD =~ /DESTROY/;

    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) 
    {
	    croak "Your vendor has not defined Sys::Utmp macro $constname";
    }
    {
	no strict 'refs';
	*{$AUTOLOAD} = sub { $val };
    }
    goto &$AUTOLOAD;
}


1;

bootstrap Sys::Utmp $VERSION;

__END__

=head2 EXPORT

No methods or constants are exported by default.

=head2 Exportable constants

These constants are exportable under the tag ':constants':

     ACCOUNTING
     BOOT_TIME
     DEAD_PROCESS
     EMPTY
     INIT_PROCESS
     LOGIN_PROCESS
     NEW_TIME
     OLD_TIME
     RUN_LVL
     USER_PROCESS

These are the values that will be found in the ut_type field of the
L<Sys::Utmp::Utent> object.

These constants are exported under the tag ':fields' :

     UT_USER
     UT_ID
     UT_LINE
     UT_PID
     UT_TYPE
     UT_HOST
     UT_TIME

These provide the indexes into the list returned when C<getutent> is called
in list context.

=head1 BUGS

Probably.  This module has been tested on Linux, Solaris, FreeBSD ,SCO 
Openserver and SCO UnixWare and found to work on those platforms.  
If you have difficulty building the module or it doesnt behave as expected
then please contact the author including if appropriate your /usr/include/utmp.h

Patches to make this work better on any platform are always welcome. The source
is managed at https://github.com/jonathanstowe/Sys-Utmp so feel free to fork and
send a pull request.

=head1 AUTHOR

Jonathan Stowe, E<lt>jns@gellyfish.co.ukE<gt>

=head1 LICENCE

This Software is Copyright Netscalibur UK 2001,  
                           Jonathan Stowe 2001-2013

This Software is published as-is with no warranty express or implied.

This is free software and can be distributed under the same terms as
Perl itself.

=head1 SEE ALSO

L<perl>. L<Sys::Utmp::Utent>

=cut
