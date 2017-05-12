package Net::Radio::oFono;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono - Perl API to oFono

=cut

our $VERSION = '0.001';

use Net::Radio::oFono::Manager;
use Net::Radio::oFono::Modem;
use Net::Radio::oFono::SimManager;
use Net::Radio::oFono::RadioSettings;
use Net::Radio::oFono::NetworkRegistration;
use Net::Radio::oFono::ConnectionManager;
use Net::Radio::oFono::MessageManager;
use Net::Radio::oFono::MessageWaiting;
use Net::Radio::oFono::CellBroadcast;

use Log::Any qw($log);

use base qw(Net::Radio::oFono::Helpers::EventMgr);

=head1 SYNOPSIS

This is the frontend API to communicate with the oFono daemon over DBus.

    use Net::Radio::oFono;

    my $oFono = Net::Radio::oFono->new();
    my @modems = $oFono->get_modems();
    foreach my $modem_path (@modems)
    {
	my $nwreg = $oFono->get_modem_interface("NetworkRegistration");
	if( $nwreg )
	{
	    if( $nwreg->GetProperty("Status", 1) eq "registered" )
	    {
		say "Network for modem '" . $modem_path . "': ", $nwreg->GetProperty("Name");
	    }
	    else
	    {
		say "Network for modem '" . $modem_path . "' is in status ", $nwreg->GetProperty("Status");
	    }
	}
	else
	{
	    say "No network registration for modem $modem_path";
	}
    }
    
    # or use the event API
    my $oFono = Net::Radio::oFono->new(
      "ON_NETWORKREGISTRATION_PROPERTY_NAME_CHANGED" => sub {
	  my ( $ofono, $event, $info ) = @_;
	  my ( $modem_path, $name ) = @$info;
	  say "Network for modem '" . $modem_path . "': ", $name;
      },
      ...
    );

=head1 INHERITANCE

  Net::Radio::oFono
  ISA Net::Radio::oFono::Helpers::EventMgr

=head1 EVENTS

Instances of Net::Radio::oFono can trigger following events (all
characters are upper cased):

=over 16

=item ON_MODEM_ADDED

Triggered when a new modem is added. On initialization, it is triggered
for each found modem.

Parameters:

=over 20

=item $modem_path

D-Bus object path to the modem oject.

=back

=item ON_MODEM_REMOVED

Triggered when a modem is removed. On destrcution, it is triggered
for each remaining modem.

Parameters:

=over 20

=item $modem_path

D-Bus object path to the modem oject.

=back

=item ON_MODEM_INTERFACE_ADDED

Triggered when an interface is added to a modem object.
Modem interfaces depend on the modem states, for example the I<SimManager>
interface is always available when the modem is I<Powered>.

Parameters:

=over 20

=item $modem_path

D-Bus object path to the modem oject.

=item $interface

The name of the propagated interface (eg. I<SimManager>, I<RadioSettings>, ...)

=back

=item ON_MODEM_INTERFACE_ . $interface . _ADDED

Triggered when an interface is added to a modem object.
Modem interfaces depend on the modem states, for example the I<SimManager>
interface is always available when the modem is I<Powered>.

The advantage of this event compared to I<ON_MODEM_INTERFACE_ADDED> is the
delegation of the dispatching for different interfaces to the EventMgr.

Parameters:

=over 20

=item $modem_path

D-Bus object path to the modem oject.

=back

=item ON_MODEM_INTERFACE_REMOVED

Triggered when an interface is removed from a modem object.
Modem interfaces depend on the modem states, for example the I<SimManager>
interface is always available when the modem is I<Powered> and will be
removed when the modem is turned off.

Parameters:

=over 20

=item $modem_path

D-Bus object path to the modem oject.

=item $interface

The name of the propagated interface (eg. I<SimManager>, I<RadioSettings>, ...)

=back

=item ON_MODEM_INTERFACE_ . $interface . _REMOVED

Triggered when an interface is removed from a modem object.
Modem interfaces depend on the modem states, for example the I<SimManager>
interface is always available when the modem is I<Powered> and will be
removed when the modem is turned off.

The advantage of this event compared to I<ON_MODEM_INTERFACE_REMOVED> is the
delegation of the dispatching for different interfaces to the EventMgr.

Parameters:

=over 20

=item $modem_path

D-Bus object path to the modem oject.

=back

=item ON_ . $interface . _PROPERTY_CHANGED

Triggered when a property of a modem object or modem interface object
is changed. I<Modem> is handled as any other interface for this event.

Typical name for such an event is I<ON_SIMMANAGER_PROPERTY_CHANGED>.

Parameters:

=over 20

=item $modem_path

D-Bus object path to the modem oject.

=item $property

Name of the changed property.

=back

=item ON_ . $interface . _PROPERTY_ . $property . _CHANGED

Triggered when a property of a modem object or modem interface object
is changed. I<Modem> is handled as any other interface for this event.

Typical name for such an event is I<ON_SIMMANAGER_PROPERTY_PINREQUIRED_CHANGED>.

The advantage of this event compared to I<ON_ . $interface . _PROPERTY_CHANGED>
is the delegation of the dispatching for different properties to the EventMgr.

Parameters:

=over 20

=item $modem_path

D-Bus object path to the modem oject.

=item $property_value

The value of the changed property.

=back

=back

=head1 SUBROUTINES/METHODS

=head2 new(%events)

Instantiates new oFono frontend accessor, registers specified events and
initializes the modem manager. Events between frontend accessor and
wrapper classes are separated.

=cut

sub new
{
    my ( $class, %events ) = @_;

    my $self = __PACKAGE__->SUPER::new(%events);
    bless( $self, __PACKAGE__ );
    $self->_init();

    return $self;
}

=head2 _init()

Initializes the frontend accessor component:

=over 4

=item *

Instantiates L<Net::Radio::oFono::Manager>.

=item *

Instantiates L<Net::Radio::oFono::Modem> for each already known modem device
using L</_add_modem>.

=item *

Registers events C<ON_MODEM_ADDED> and C<ON_MODEM_REMOVED> on the manager.

=back

=cut

sub _init
{
    my $self = shift;

    $self->{manager} = Net::Radio::oFono::Manager->new();

    my %modems = $self->{manager}->GetModems();
    $self->{modems} = {};
    foreach my $modem_path ( keys %modems )
    {
        $self->_add_modem($modem_path);
    }

    $self->{manager}->add_event( "ON_MODEM_ADDED",   \&on_modem_added,   $self );
    $self->{manager}->add_event( "ON_MODEM_REMOVED", \&on_modem_removed, $self );

    return $self;
}

sub DESTROY
{
    my $self = $_[0];

    foreach my $modem_path ( keys %{ $self->{modems} } )
    {
        $self->_remove_modem($modem_path);
    }

    delete $self->{modems};
    delete $self->{manager};

    return;
}

=head2 _add_modem

Internal method to properly add a modem to the frontend for accessing it.

Registers the events C<ON_PROPERTY_CHANGED> and
C<ON_PROPERTY_INTERFACES_CHANGED> on the created object.

Triggers the event C<ON_MODEM_ADDED> when finished with that procedure.

=cut

sub _add_modem
{
    my ( $self, $modem_path ) = @_;

    my $modem = Net::Radio::oFono::Modem->new($modem_path);
    $self->{modems}->{$modem_path}->{Modem} = $modem;

    $modem->add_event( "ON_PROPERTY_CHANGED",            \&on_property_changed,         $self );
    $modem->add_event( "ON_PROPERTY_INTERFACES_CHANGED", \&on_modem_interfaces_changed, $self );

    $self->_update_modem_interfaces($modem);

    $self->trigger_event( "ON_MODEM_ADDED", $modem_path );

    return;
}

=head2 _remove_modem

Internal method to properly remove a modem from the frontend for accessing it.

Removes all interfaces objects from the modem using
L</_update_modem_interfaces> mocking and empty interface list and finally
destroy the modem object itself.

Triggers C<ON_MODEM_REMOVED> when the procedure has completed.

=cut

sub _remove_modem
{
    my ( $self, $modem_path ) = @_;

    defined( $self->{modems}->{$modem_path} ) or return;

    $self->_update_modem_interfaces( $self->{modems}->{$modem_path}->{Modem}, [] );
    delete $self->{modems}->{$modem_path};

    $self->trigger_event( "ON_MODEM_REMOVED", $modem_path );

    return;
}

sub _create_remote_obj
{
    my ( $self, $if_class, $obj_path ) = @_;
    my %events = ();

    $if_class->DOES("Net::Radio::oFono::Roles::Properties")
      and $events{ON_PROPERTY_CHANGED} = {
                                           FUNC => \&on_property_changed,
                                           MEMO => $self
                                         };
    if ( $if_class->DOES("Net::Radio::oFono::Roles::Manager") )
    {
        my $type = uc( $if_class->_get_managed_type() );
        $events{ "ON_" . $type . "_ADDED" } = {
                                                FUNC => \&on_object_added,
                                                MEMO => $self
                                              };
        $events{ "ON_" . $type . "_REMOVED" } = {
                                                  FUNC => \&on_object_removed,
                                                  MEMO => $self
                                                };
    }

    if ( $if_class->can("_extra_events") )
    {
        my @extra_events = $if_class->_extra_events();
        foreach my $extra_event (@extra_events)
        {
            $events{$extra_event} = {
                                      FUNC => \&on_extra_event,
                                      MEMO => $self
                                    };
        }
    }

    return $if_class->new( $obj_path, %events );
}

=head2 _update_modem_interfaces

Internal function to adjust the interface objects of a remote modem objects.
It iterates over the list of the available interfaces of the "Interfaces"
property of the modem object to instantiate a new interface object for newly
added ones and removes those objects of interfaces which are removed.

Triggers the events C<ON_MODEM_INTERFACE_ADDED> and
C<ON_MODEM_INTERFACE_ . uc($interface) . _ADDED> for each newly instantiated
interface. Triggers the events C<ON_MODEM_INTERFACE_REMOVED> and
C<ON_MODEM_INTERFACE_ . uc($interface) . _REMOVED> for each interface which
was removed.

=cut

sub _update_modem_interfaces
{
    my ( $self, $modem, $interfaces ) = @_;
    $interfaces //= $modem->GetProperty("Interfaces");
    my @interface_list = map { ( my $pure = $_ ) =~ s/org.ofono.//; $pure } @$interfaces;
    my $if_instances = $self->{modems}->{ $modem->modem_path() };
    my %superflous_if_instances = map { $_ => 1 } keys %$if_instances;
    delete $superflous_if_instances{Modem};

    foreach my $interface (@interface_list)
    {
        delete $superflous_if_instances{$interface};
        my $if_class = "Net::Radio::oFono::$interface";
        $if_class->isa("Net::Radio::oFono::Modem") or next;
        defined( $if_instances->{$interface} ) and next;
        my $modem_path = $modem->modem_path();
        $if_instances->{$interface} = $self->_create_remote_obj( $if_class, $modem_path );
        $self->trigger_event( "ON_MODEM_INTERFACE_ADDED", [ $modem_path, $interface ] );
        $self->trigger_event( "ON_MODEM_INTERFACE_" . uc($interface) . "_ADDED", $modem_path );
    }

    foreach my $interface ( keys %superflous_if_instances )
    {
        delete $if_instances->{$interface};
        my $modem_path = $modem->modem_path();
        $self->trigger_event( "ON_MODEM_INTERFACE_REMOVED", [ $modem_path, $interface ] );
        $self->trigger_event( "ON_MODEM_INTERFACE_" . uc($interface) . "_REMOVED", $modem_path );
    }

    return;
}

=head2 get_modems(;$force)

Returns the list of object path's for currently known (and instantiated)
modem objects.

TODO: implement way to get without Net::DBus::Reactor->main->run() ...

=cut

sub get_modems
{
    my ( $self, $force ) = @_;

    $force and $self->{manager}->GetModems(1);

    return keys %{ $self->{modems} };
}

=head2 get_modem_interface($modem_path,$interface)

Returns the object for the specified interface on the given modem object.
If either the modem device isn't known or the interface isn't available
yet, it returns nothing.

=cut

sub get_modem_interface
{
    my ( $self, $modem_path, $if_name ) = @_;
    defined( $self->{modems}->{$modem_path} )
      and defined( $self->{modems}->{$modem_path}->{$if_name} )
      and return $self->{modems}->{$modem_path}->{$if_name};
    return;
}

sub _add_managed_object
{
    my ( $self, $mgr_type, $mgmt_type, $obj_path ) = @_;

    my $hn       = lc($mgmt_type) . "s";
    my $if_class = "Net::Radio::oFono::" . $mgmt_type;

    $self->{$hn}->{$obj_path}->{$mgmt_type} = $self->_create_remote_obj( $if_class, $obj_path );

    $self->trigger_event( "ON_" . uc($mgr_type) . "_" . uc($mgmt_type) . "_ADDED", $obj_path );

    return;
}

sub _remove_managed_object
{
    my ( $self, $mgr_type, $mgmt_type, $obj_path ) = @_;

    my $hn = lc($mgmt_type) . "s";
    defined( $self->{$hn}->{$obj_path} ) or return;

    delete $self->{$hn}->{$obj_path};

    $self->trigger_event( "ON_" . uc($mgr_type) . "_" . uc($mgmt_type) . "_REMOVED", $obj_path );

    return;
}

=head2 get_remote_object($type,$obj_path;$if_name)

Returns the object for the specified remote object on the given object path.
Missing $if_name is replaced by $type.

If one of $type, $obj_path or $if_name isn't available, nothing is returned.

=cut

sub get_remote_object
{
    my ( $self, $type, $obj_path, $if_name ) = @_;
    my $hn = lc($type) . "s";
    $if_name //= $type;

    defined( $self->{$hn} ) or return $self->get_modem_interface( $obj_path, $if_name );
    defined( $self->{$hn}->{$obj_path} )
      and defined( $self->{$hn}->{$obj_path}->{$if_name} )
      and return $self->{$hn}->{$obj_path}->{$if_name};

    return;
}

=head2 on_modem_added

Invoked when the even C<ON_MODEM_ADDED> is triggered by the modem
manager and invokes L</_add_modem> for the submitted object path.

=cut

sub on_modem_added
{
    my ( $self, $manager, $event, $modem_path ) = @_;

    $self->_add_modem($modem_path);

    return;
}

=head2 on_modem_removed

Invoked when the even C<ON_MODEM_REMOVED> is triggered by the modem
manager and invokes L</_remove_modem> for the submitted object path.

=cut

sub on_modem_removed
{
    my ( $self, $manager, $event, $modem_path ) = @_;

    $self->_remove_modem($modem_path);

    return;
}

=head2 on_modem_interfaces_changed

Triggered when a modem object changes it's list of available interfaces
in addition to L<on_property_changed> with C<Interfaces> as name
of the changed property.

Updates active interface objects using L</_update_modem_interfaces>.

=cut

sub on_modem_interfaces_changed
{
    my ( $self, $modem, $event_name, $interfaces ) = @_;

    $self->_update_modem_interfaces( $modem, $interfaces );

    return;
}

=head2 on_object_added

Invoked when the even C<ON_ ... _ADDED> is triggered by any modem
interface with manager role when an embedded object is added. Triggers
event C<"ON_" . uc($mgr_type) . "_" . uc($mgmt_type) . "_ADDED"> with
the object path of the created object as parameter.

When a new context is added in ConnectionManager, the event
C<ON_CONNECTIONMANAGER_CONTEXT_ADDED> is triggered.

=cut

sub on_object_added
{
    my ( $self, $obj_mgr, $event, $obj_path ) = @_;
    my $mgmt_type = $obj_mgr->_get_managed_type();
    ( my $mgr_type = ref($obj_mgr) ) =~ s/Net::Radio::oFono:://;

    $self->_add_managed_object( $mgr_type, $mgmt_type, $obj_path );

    return;
}

=head2 on_object_removed

Invoked when the even C<ON_ ... _REMOVED> is triggered by any modem
interface with manager role when an embedded object is removed. Triggers
event C<"ON_" . uc($mgr_type) . "_" . uc($mgmt_type) . "_ADDED"> with the
object path of the created object as parameter.

When a context is removed from ConnectionManager, the event
C<ON_CONNECTIONMANAGER_CONTEXT_REMOVED> is triggered.

=cut

sub on_object_removed
{
    my ( $self, $obj_mgr, $event, $obj_path ) = @_;
    my $mgmt_type = $obj_mgr->_get_managed_type();
    ( my $mgr_type = ref($obj_mgr) ) =~ s/Net::Radio::oFono:://;

    $self->_remove_managed_object( $mgr_type, $mgmt_type, $obj_path );

    return;
}

=head2 on_property_changed

Triggered when a modem object modifies a property.

Triggers C<ON_ . uc($interface) . _PROPERTY_CHANGED> with modem path and
property name as parameter as well as
C<ON_ . uc($interface) . _PROPERTY_ . uc($property) . _CHANGED> with
modem path and property value as parameter.

=cut

sub on_property_changed
{
    my ( $self, $obj, $event_name, $property ) = @_;
    my $modem_path = $obj->modem_path();
    ( my $if_name = ref($obj) ) =~ s/.*://;

    $self->trigger_event( "ON_" . uc($if_name) . "_PROPERTY_CHANGED", [ $modem_path, $property ] );
    $self->trigger_event( "ON_" . uc($if_name) . "_PROPERTY_" . uc($property) . "_CHANGED",
                          [ $modem_path, $obj->GetProperty($property) ] );

    return;
}

=head2 on_extra_event

Triggered when any managed remote object fires an event which is not
usually watched. This event is enriched with some information about the
original sender:

=over 4

=item *

The name of the event is modified by placing the upper cased basename of
the triggering object interface directly behind the leading "ON_".

=item *

The list of arguments is prepended by the basename of the triggering
object and the object path of the triggering object.

=back

Use L</get_remote_object($type,$obj_path;$if_name)|get_remote_object($type,$obj_path)>
to get the object instance.

=cut

sub on_extra_event
{
    my ( $self, $obj, $event_name, $arg ) = @_;

    my @event_parts = split( "_", $event_name );
    ( my $type = ref($obj) ) =~ s/Net::Radio::oFono:://;
    splice( @event_parts, 1, 0, uc($type) );

    my $fwd_arg =
      _ARRAY($arg) ? [ $type, $obj->obj_path(), @$arg ] : [ $type, $obj->obj_path(), $arg ];
    $self->trigger_event( join( "_", @event_parts ), $fwd_arg );

    return;
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-radio-ofono at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Radio-oFono>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radio::oFono

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Radio-oFono>

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Radio-oFono>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Radio-oFono>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Radio-oFono/>

=back

=head2 Where can I go for help with a concrete version?

Bugs and feature requests are accepted against the latest version
only. To get patches for earlier versions, you need to get an
agreement with a developer of your choice - who may or not report the
issue and a suggested fix upstream (depends on the license you have
chosen).

=head2 Business support and maintenance

For business support you can contact Jens via his CPAN email
address rehsackATcpan.org. Please keep in mind that business
support is neither available for free nor are you eligible to
receive any support based on the license distributed with this
package.

=head1 ACKNOWLEDGEMENTS

At first the guys from the oFono-Team shall be named: Marcel Holtmann and
Denis Kenzior, the maintainers and all the people named in ofono/AUTHORS.
Without their effort, there would no need for a Net::Radio::oFono module.

Further, Peter "ribasushi" Rabbitson helped a lot by providing hints
and support how to make this API accessor a valuable CPAN module.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Net::Radio::oFono
