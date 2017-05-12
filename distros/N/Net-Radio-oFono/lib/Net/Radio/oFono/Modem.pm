package Net::Radio::oFono::Modem;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono::Modem - access to oFono's Modem objects

=cut

our $VERSION = '0.001';

use base
  qw(Net::Radio::oFono::Helpers::EventMgr Net::Radio::oFono::Roles::RemoteObj Net::Radio::oFono::Roles::Properties);

use Net::DBus qw(:typing);

use Log::Any qw($log);

=head1 SYNOPSIS

Provides access to oFono's Modem objects with org.ofono.Modem interface.

  use Net::Radio::oFono::Modem;
  ...
  my $modem = Net::Radio::oFono::Modem->new("/option_0");
  if( !$modem->GetProperty("Online") )
  {
      $modem->SetProperty("Online", dbus_boolean(1) );
  }

Usually modem objects are accessed via L<Net::Radio::oFono/get_modem_interface>:

  $oFono->get_modem_interface("Modem")->SetProperty("Online", dbus_boolean(1) );

=head1 INHERITANCE

  Net::Radio::oFono::Modem
  ISA Net::Radio::oFono::Helpers::EventMgr
  DOES Net::Radio::oFono::Roles::RemoteObj
  DOES Net::Radio::oFono::Roles::Properties

=head1 EVENTS

No additional events are triggered.

=head1 METHODS

=head2 new($obj_path;%events)

Instantiates new object for org.ofono.Modem interfaced objects.

=cut

sub new
{
    my ( $class, $obj_path, %events ) = @_;

    my $self = $class->SUPER::new(%events);

    bless( $self, $class );

    $self->_init($obj_path);

    return $self;
}

=head2 _init($obj_path)

Initializes the Modem interface. Using the "basename" of the instantiated package
as interface name for the RemoteObj role.

=cut

sub _init
{
    my ( $self, $obj_path ) = @_;

    ( my $interface = ref($self) ) =~ s/Net::Radio::oFono:://;

    # initialize roles
    $self->Net::Radio::oFono::Roles::RemoteObj::_init( $obj_path, "org.ofono.$interface" );
    $self->Net::Radio::oFono::Roles::Properties::_init();

    return;
}

=head2 modem_path

Alias for C<obj_path> getter of RemoteObj role.

=cut

# let us inject this, too?
sub modem_path
{
    return $_[0]->{obj_path};
}

sub DESTROY
{
    my $self = $_[0];

    # destroy roles
    $self->Net::Radio::oFono::Roles::Properties::DESTROY();
    $self->Net::Radio::oFono::Roles::RemoteObj::DESTROY();

    # destroy base class
    $self->Net::Radio::oFono::Helpers::EventMgr::DESTROY();

    return;
}

1;
