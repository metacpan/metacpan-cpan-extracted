package Sys::Utmp::Utent;

=head1 NAME

Sys::Utmp::Utent  - represent a single utmp entry

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

=head1 DESCRIPTION

As described in the L<Sys::Utmp> documentation the getutent method
returns an object of the type Sys::Utmp::Utent which provides methods
for accessing the fields in the utmp record.  There are also methods
for determining the type of the record.

The access methods relate to the common names for the members of the C
struct utent - those provided are the superset from the Gnu implementation
and may not be available on all systems: where they are not they will
return the empty string.

=over 4

=item  ut_user

Returns the use this record was created for if this is a record for a user
process.  Some systems may return other information depending on the record
type.  If no user was set this will be the empty string.  If tainting is
switched on with the '-T' switch to perl then this will be 'tainted' as it
is possible that the user name came from an untrusted source.

=item  ut_id

The identifier for this record - it might be the inittab tag or some other
system dependent value.

=item ut_line

For user process records this will be the name of the terminalor line that the
user is connected on.

=item  ut_pid

The process ID of the process that created this record.

=item ut_type

The type of the record this will have a value corresponding to one of the
constants (not all of these may be available on all systems and there may
well be others which should be described in the getutent manpage or in
/usr/include/utmp.h ) :

=over 2

=item ACCOUNTING - record was created for system accounting purposes.

=item BOOT_TIME - the record was created at boot time.

=item DEAD_PROCESS - The process that created this record has terminated.

=item EMPTY  - record probably contains no other useful information.

=item INIT_PROCESS - this is a record for process created by init.

=item LOGIN_PROCESS - this record was created for a login process (e.g. getty).

=item NEW_TIME  - record created when the system time has been set.

=item OLD_TIME - record recording the old tme when the system time has been set.

=item RUN_LVL - records the time at which the current run level was started.

=item USER_PROCESS - record created for a user process (e.g. a login )

=back

for convenience Sys::Utmp::Utent provides methods which are lower case
versions of the constant names which return true if the record is of that
type.

=item ut_host

On systems which support this the method will return the hostname of the 
host for which the process that created the record was started - for example
for a telnet login.  If taint checking has been turned on (with the -T
switch to perl )  then this value will be tainted as it is possible that
a remote user will be in control of the DNS for the machine they have
logged in from. ( see L<perlsec> for more on tainting )

=item ut_time

The time in epoch seconds wt which the record was created.

=back

=cut

use strict;
use warnings;

use Carp;
require Exporter;


use vars qw(
             @methods
             %meth2index
             %const2meth
             $AUTOLOAD
             @ISA
             @EXPORT
           );

@ISA = qw(Exporter);

BEGIN
{
   @methods = qw(
                 ut_user
                 ut_id
                 ut_line
                 ut_pid
                 ut_type
                 ut_host
                 ut_time
               );


   @meth2index{@methods} = ( 0 .. $#methods );
   

   no strict 'refs';
   foreach my $sub ( @methods )
   {
     my $usub = uc $sub;

     *{$usub} = sub { return $meth2index{$sub} };
     push @EXPORT, $usub;

   }
   use strict 'refs';

   $const2meth{lc $_ } = $_ foreach @Sys::Utmp::constants;

}

sub AUTOLOAD
{
   my ( $self ) = @_;

   return if ( $AUTOLOAD =~ /DESTROY/ );

  (my $methname = $AUTOLOAD) =~ s/.*:://;


  {
    no strict 'refs';

     if ( exists $meth2index{$methname} )
     { 
        *{$AUTOLOAD} = sub { 
                             my ($self) = @_;
                             return $self->[$meth2index{$methname}];
                            };
      }
      elsif ( exists $const2meth{$methname})
      {
         *{$AUTOLOAD} = sub {
                              my ( $self ) = @_;
                              return $self->ut_type == &{"Sys::Utmp::$const2meth{$methname}"};
                             };
       }
       else
       {
         croak "$methname not defined" unless exists $meth2index{$methname};
       }

       goto &{$AUTOLOAD};
   }
}

1;

__END__

=head1 BUGS

Probably.  This module has been tested on Linux, Solaris, FreeBSD ,SCO 
Openserver and SCO UnixWare and found to work on those platforms.  
If you have difficulty building the module or it doesnt behave as expected
then please contact the author including if appropriate your /usr/include/utmp.h

=head1 AUTHOR

Jonathan Stowe, E<lt>jns@gellyfish.co.ukE<gt>

=head1 LICENCE

This Software is Copyright Jonathan Stowe 2001-2013

This Software is published as-is with no warranty express or implied.

This is free software and can be distributed under the same terms as
Perl itself.

=head1 SEE ALSO

L<perl>. L<Sys::Utmp>

=cut
