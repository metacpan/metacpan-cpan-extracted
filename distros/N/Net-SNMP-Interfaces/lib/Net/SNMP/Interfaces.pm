#*****************************************************************************
#*                                                                           *
#*                          Gellyfish Software                               *
#*                                                                           *
#*                                                                           *
#*****************************************************************************
#*                                                                           *
#*      PROGRAM     :  Net::SNMP::Interfaces.                                *
#*                                                                           *
#*      AUTHOR      :  JNS                                                   *
#*                                                                           *
#*      DESCRIPTION :  Simple SNMP stuff for Interfaces.                     *
#*                                                                           *
#*                                                                           *
#*****************************************************************************

package Net::SNMP::Interfaces;

=head1 NAME

Net::SNMP::Interfaces - provide simple methods to gain interface data via

SNMP

=head1 SYNOPSIS

    use Net::SNMP::Interfaces;

    my $interfaces = Net::SNMP::Interfaces->new(Hostname => 'localhost',
                                                Community => 'public' );

    my @ifnames = $interfaces->all_interfaces();

=head1 DESCRIPTION

Net::SNMP::Interfaces aims to provide simple object methods to obtain
information about a host's network interfaces ( be it a server a router
or whatever ).  The motivation was largely to allow a programmer to use
SNMP to obtain this information without needing to know a great deal
about the gory details.

The module uses Net::SNMP under the hood to do the dirty work although
the user shouldn't have to worry about that ( the Net::SNMP object is
available though for those who might feel the need ).

The actual details for a particular interface are obtained from the methods
of Net::SNMP::Interfaces::Details - objects of which type can be obtained
for the methods all_interfaces() and interface().

Of course the simpler interface has its limitations and there may well
be things that you would like to do which you cant do with this module -
in which case I would recommend that you get a good book on SNMP and
use Net::SNMP :)

The module uses blocking SNMP requests at the current time so if some
of the methods are taking too long you may want to time them out
yourself using alarm().

=cut



use strict;
use Net::SNMP;
use Carp;


use Net::SNMP::Interfaces::Details;

use vars qw(
            @ISA
            $VERSION
            $AUTOLOAD
           );
             


($VERSION) = q$Revision: 1.4 $ =~ /([\d.]+)/;

=head2 METHODS

=over

=item new(  HASH %args )

The constructor of the class. It takes several arguments that are passed
to Net::SNMP :

=over

=item Hostname

The name of the host which you want to connect to. Defaults to 'localhost'.

=item Community

The SNMP community string which you want to use for this session.  The default
is 'public'.

=item Port

The UDP port that the SNMP service is listening on.  The default is 161.

=item Version

The SNMP version (as described in the L<Net::SNMP> documentation) to be
used.  The default is 'snmpv1'.  Support for SNMPv3 is currently somehwat
limited.

=back

There is a also an optional argument 'RaiseError' which determines
the behaviour of the module in the event there is an error while creating
the SNMP.  Normally new() will return undef if there was an error but if
RaiseError is set to a true value it will die() printing the error string
to STDERR.  If this is not set and an error occurs undef will be return
and the variable $Net::SNMP::Interfaces::error will contain the test of
the error.

Because the interfaces are discovered in the constructor, if the module
is to be used in a long running program to monitor a host where 
interfaces might be added or removed it is recommended that the object
returned by new() is periodically destroyed and a new one constructed.

=cut


sub new
{
  my ( $proto , %args ) = @_;
  
  my $self = {};

  $self->{_hostname}  = $args{Hostname}  || 'localhost';
  $self->{_community} = $args{Community} || 'public';
  $self->{_port}      = $args{Port}      || 161;
  $self->{_version}   = $args{Version}   || 'snmpv1',
  $self->{_raise}     = $args{RaiseError} || 0;


  my ($session, $error) = Net::SNMP->session(
                                              -hostname  => $self->{_hostname},
                                              -community => $self->{_community},
                                              -port      => $self->{_port},
                                              -version   => $self->{_version},
                                            );

  if (!defined($session)) 
  {
     if ( $self->{_raise} )
     {
       croak sprintf("%s: %s", __PACKAGE__, $error);
     }
     else
     {
       $Net::SNMP::Interfaces::error = $error;
       return undef;
     }
  }

  $self->{_snmp_session} = $session;

  my $ifIndex = '1.3.6.1.2.1.2.2.1.1';
  my $ifDescr = '1.3.6.1.2.1.2.2.1.2';

  my $response;

  if (!defined($response = $session->get_table($ifIndex))) 
  {
     if ( $self->{_raise} )
     {
       $session->close;
       croak sprintf("%s: %s",__PACKAGE__, $session->error);
     }
     else
     {
       $Net::SNMP::Interfaces::error = $session->error();
       return undef;
     }
  }


  foreach my $index ( values %{$response} )
  {
    my $this_desc = "$ifDescr.$index"; 

    my $description;

    if ( defined( $description = $session->get_request($this_desc)) )
    {
      $self->{_desc2index}->{$description->{$this_desc}} = $index;
      $self->{_index2desc}->{$index} = $description->{$this_desc};
    }
    else
    {
      $self->{_lasterror} = $session->error();
    }
  }  

  return bless $self, $proto;
}

=item if_names()

Returns a list of the interface names.

=cut

sub if_names
{
   my ( $self ) = @_;

   return keys %{$self->{_desc2index}};
}


=item if_indices()

Returns a list of the indices of the interfaces - this probably shouldn't
be necessary but is here for completeness anyway.  If you dont know what
the index is for you are safe to ignore this.

=cut

sub if_indices
{
   my ( $self ) = @_;

   return keys %{$self->{_index2desc}};
}

=item  error()

Returns the text of the last Net::SNMP error.  This method only makes sense
if the previous method call indicated an error by a false return.

=cut

sub error
{
  my ($self ) = @_;

  return $self->{_lasterror} || $self->session()->error();
}

=item session()

Returns the Net::SNMP session object for this instance. Or a false value
if there is no open session.  This might be used to call methods on the
Net::SNMP object if some facility is needed that isnt supplied by this
module.

=cut

sub session
{
  my ( $self ) = @_;

  return exists $self->{_snmp_session} ? $self->{_snmp_session} : undef;
}

=item all_interfaces()

Returns a list of Net::SNMP::Interface::Details objects corresponding to
the interfaces discovered on this host.  In scalar context it will return
a reference to an array.

=cut

sub all_interfaces
{
  my ( $self ) = @_;

  my @interfaces;

  
  for my $index ( sort $self->if_indices() )
  {
    my %args = (
                 Index   => $index,
                 Name    => $self->{_index2desc}->{$index},
                 Session => $self->session()
               );

    push @interfaces, Net::SNMP::Interfaces::Details->new(%args);
  }

  return wantarray ? @interfaces : \@interfaces;
}

=item interface( SCALAR $name )

Returns a Net::SNMP::Interfaces::Details object for the named interface.
Returns undef if the supplied name is not a known interface.

=cut

sub interface
{
  my ( $self, $name ) = @_;

  my $index = $self->{_desc2index}->{$name};

  if ( defined $index )
  {
    return Net::SNMP::Interfaces::Details->new(
                                               Name    => $name,
                                               Index   => $index,
                                               Session => $self->session()
                                              );
  }
  else
  {
    return undef;
  }
}

=for pod

In addition to the methods above, you can also use the methods from
Net::SNMP::Interfaces::Details but with the addition of the interface
name as an argument. e.g:

      $in_octs = $self->ifInOctets('eth0');

Please see the documentation for Net::SNMP::Interfaces::Details for more
on these methods.

=cut

sub AUTOLOAD
{
  my ( $self, $name ) = @_;

  return if $AUTOLOAD =~ /DESTROY$/;

  croak "No name" unless $name;
  return undef unless exists $self->{_desc2index}->{$name};

  my ($meth)  = $AUTOLOAD =~ /::([^:]+)$/;

  no strict 'refs';

  *{$AUTOLOAD} = sub {
                        my ( $self, $name ) = @_;
                        return $self->interface($name)->$meth() ;
                     };

  goto &{$AUTOLOAD};

}


sub DESTROY
{
  my ( $self ) = @_;

  $self->session()->close();
}

1;
__END__

=head1 SUPPORT

The code is host on Github at 

     https://github.com/jonathanstowe/Net-SNMP-Interfaces

Pull requests are welcome, especially if they help support SNMPv3 better.

Email to <bug-Net-SNMP-Interfaces@rt.cpan.org> is preferred for non-patch
requests.

=head1 AUTHOR

Jonathan Stowe <jns@gellyfish.co.uk>

=head1 COPYRIGHT

Copyright (c) Jonathan Stowe 2000 -2013.  All rights reserved.  This is free
software it can be ditributed and/or modified under the same terms as
Perl itself.

=head1 SEE ALSO

perl(1), L<Net::SNMP>, L<Net::SNMP::Interfaces::Details>.

=cut
