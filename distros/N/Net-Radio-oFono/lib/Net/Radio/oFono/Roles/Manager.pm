package Net::Radio::oFono::Roles::Manager;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono::Roles::Manager - Role for Interfaces which manages objects

=head1 DESCRIPTION

This package provides a role for being added to classes which need to manages
embedded remote objects in remote dbus object.

=cut

our $VERSION = '0.001';

# must be done by embedding class
# use base qw(Net::Radio::oFono::Helpers::EventMgr);

use Net::DBus qw(:typing);
use Carp qw/croak/;

use Log::Any qw($log);

=head1 SYNOPSIS

    package Net::Radio::oFono::NewInterface;

    use Net::Radio::oFono::Roles::Manager qw(Embed);
    use base qw(Net::Radio::oFono::Helpers::EventMgr? Net::Radio::oFono::Roles::RemoteObj Net::Radio::oFono::Roles::Manager ...);

    use Net::DBus qw(:typing);

    sub new
    {
	my ( $class, %events ) = @_;

	my $self = $class->SUPER::new(%events); # SUPER::new finds first - so EventMgr::new

	bless( $self, $class );

	$self->_init();

	return $self;
    }

    sub _init
    {
	my $self = $_[0];

	# initialize roles
	$self->Net::Radio::oFono::Roles::RemoteObj::_init( "/modem_0", "org.ofono.NewInterface" ); # must be first one
	$self->Net::Radio::oFono::Roles::Manager::_init( "Embed", "NewEmbed" );
	...

	return;
    }

    sub DESTROY
    {
	my $self = $_[0];

	# destroy roles
	...
	$self->Net::Radio::oFono::Roles::Manager::DESTROY(); # must be last one
	$self->Net::Radio::oFono::Roles::RemoteObj::DESTROY(); # must be last one

	# destroy base class
	$self->Net::Radio::oFono::Helpers::EventMgr::DESTROY();

	return;
    }

=head1 EVENTS

Following events are triggered by this role:

=over 4

=item ON_ . uc($type) . _ADDED

Triggered when a new object of specified type was added.

=item ON_ . uc($type) . _REMOVED

Triggered when an object of specified type is removed.

=back

=head1 FUNCTIONS

=head2 import($type;$interface)

When invoked, getters for embedded objects are injected into caller's
namespace using the generic L</GetObjects> and L</GetObject> as well
as required static methods for managed types.

Using the MessageManager example:

    package Net::Radio::oFono::MessageManager;
    ...
    use Net::Radio::oFono::Roles::Manager qw(Message);

Injects C<GetMessages> and C<GetMessage> into
Net::Radio::oFono::MessageManager,
using C<GetObjects> for C<GetMessages> and
C<GetObject> for C<GetMessage>. Injects C<_get_managed_type>
and C<_get_managed_interface> into Net::Radio::oFono::MessageManager,
returning C<Message> as descriptive type and C<Message> as interface
or class type, respectively.

    package Net::Radio::oFono::NetworkRegistration;
    ...
    use Net::Radio::oFono::Roles::NetworkRegistration qw(Operator NetworkOperator);

Injects C<GetOperators> and C<GetOperator> into
Net::Radio::oFono::NetworkRegistration,
using C<GetObjects> for C<GetOperators> and
C<GetObject> for C<GetOperator>. Injects C<_get_managed_type>
and C<_get_managed_interface> into Net::Radio::oFono::NetworkRegistration,
returning C<Operator> as descriptive type and C<NetworkOperator> as
interface or class type, respectively.

=cut

sub import
{
    my ( $me, $type, $interface ) = @_;

    $interface //= $type;
    my $caller = caller;

    if ( defined($type) && !( $caller->can("Get${type}") ) )
    {
        my $pkg = __PACKAGE__;    # avoid inheritance confusion

        my $code = <<"EOC";
package $caller;

sub Get${type}s
{
    return ${pkg}::GetObjects(\@_);
}

sub Get${type}
{
    return ${pkg}::GetObject(\@_);
}

1;
EOC
        eval $code or die "Can't inject provides-API";
    }

    if ( defined($interface) && !( $caller->can("_get_managed_type") ) )
    {
        my $pkg = __PACKAGE__;    # avoid inheritance confusion

        my $code = <<"EOC";
package $caller;

sub _get_managed_type
{
    return "${type}";
}

sub _get_managed_interface
{
    return "${interface}";
}

1;
EOC
        eval $code or die "Can't inject chicken-egg-solver";
    }

    return 1;
}

=head1 METHODS

=head2 _init()

Initializes the manager role of the object.

C<$type> and $<$interface> are the spoken type of the embedded object
(for signals, events) and the remote interface name (without the
C<org.ofono.> prefix).

If no interface is named, the spoken type is used as interface name
(which is pretty common, like for Modem or Message).

The initialization connects to the signals C<${type}Added> and
C<${type}Removed> provided by oFono's manager objects.

=cut

sub _init
{
    my ($self) = @_;

    $self->{mgmt_type}      = $self->_get_managed_type();
    $self->{MGMT_TYPE}      = uc( $self->{mgmt_type} );
    $self->{mgmt_interface} = $self->_get_managed_interface();

    my $on_obj_added = sub { return $self->onObjectAdded(@_); };
    $self->{sig_obj_added} =
      $self->{remote_obj}->connect_to_signal( $self->{mgmt_type} . "Added", $on_obj_added );

    my $on_obj_removed = sub { return $self->onObjectRemoved(@_); };
    $self->{sig_obj_removed} =
      $self->{remote_obj}->connect_to_signal( $self->{mgmt_type} . "Removed", $on_obj_removed );

    $self->GetObjects(1);

    return;
}

=head2 DESTROY

Frees previously aquired resources like connected signals, list of managed
objects (object_path).

Must be invoked before the RemoteObject role frees it's resources ...

=cut

sub DESTROY
{
    my $self = $_[0];

    my $type = $self->{mgmt_type};
    $type or croak "Please use ogd";

    defined( $self->{remote_obj} )
      and $self->{remote_obj}->disconnect_from_signal( "${type}Added", $self->{sig_obj_added} );
    defined( $self->{remote_obj} )
      and $self->{remote_obj}->disconnect_from_signal( "${type}Removed", $self->{sig_obj_removed} );

    undef $self->{mgmt_objects};

    return;
}

=head2 GetObjects(;$force)

Returns the managed objects of the remote object as hash with the
object path as key and the properties dictionary (hash) as value.

When invoked with a true value as first argument, the managed
object list is refreshed from the remote object.

Returns the object hash in array more and the reference to the
object hash in scalar mode.

=over 8

=item B<TODO>

Return cloned objects to avoid dirtying the local cache ...

=back

=cut

sub GetObjects
{
    my ( $self, $force ) = @_;

    if ($force)
    {
        my $getter  = "Get" . $self->{mgmt_type} . "s";
        my @obj_lst = @{ $self->{remote_obj}->$getter() };
        my %mgmt_objects;

        foreach my $obj_info (@obj_lst)
        {
            $mgmt_objects{ $obj_info->[0] } = $obj_info->[1];
        }

        $self->{mgmt_objects} = \%mgmt_objects;
    }

    return wantarray ? %{ $self->{mgmt_objects} } : $self->{mgmt_objects};
}

=head2 GetObject($object_path;$force)

Returns an instance of the managed object interface identified by the specified
object path.

Take above example for C<MessageManager>, this method will return instances of
C<net::Radio::oFono::Message> using the /{modem0,modem1,...}/{message_01,...}
object path.

=cut

sub GetObject
{
    my ( $self, $obj_path, $force ) = @_;

    $force and $self->GetObjects($force);

    my $objClass = "Net::Radio::oFono::" . $self->{mgmt_interface};
    # check for package first, but Package::Util is just a reserved name and Module::Util is to stupid
    # probably $objClass->DOES($typical_role) is a way out, but it's not really the same ...
    return $objClass->new($obj_path);
}

=head2 onObjectAdded

Callback method used when the signal C<..Added> is received.
Can be overwritten to implement other or enhanced behavior.

=over 4

=item *

Updates properties cache

=item *

Triggers event for added object

=back

=cut

sub onObjectAdded
{
    my ( $self, $obj_path, $properties ) = @_;

    $self->{mgmt_objects}->{$obj_path} = $properties;
    $self->trigger_event( "ON_" . $self->{MGMT_TYPE} . "_ADDED", $obj_path );

    return;
}

=head2 onObjectRemoved

Callback method used when the signal C<..Removed> is received.
Can be overwritten to implement other or enhanced behavior.

=over 4

=item *

Updates properties cache

=item *

Triggers event for removed object

=back

=cut

sub onObjectRemoved
{
    my ( $self, $obj_path ) = @_;

    delete $self->{mgmt_objects}->{$obj_path};
    $self->trigger_event( "ON_" . $self->{MGMT_TYPE} . "_REMOVED", $obj_path );

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

1;
