package Net::Radio::oFono::ConnectionManager;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono::ConnectionManager - provide ConnectionManager interface for Modem objects

=cut

our $VERSION = '0.001';

use Net::DBus qw(:typing);

require Net::Radio::oFono::ConnectionContext;

use Net::Radio::oFono::Roles::Manager qw(Context ConnectionContext);
use base qw(Net::Radio::oFono::Modem Net::Radio::oFono::Roles::Manager);

=head1 SYNOPSIS

  my $oFono = Net::Location::oFono->new();
  my @modems = Net::Location::oFono->get_modems();
  # show default network information
  foreach my $modem_path (@modems) {
    my $conman = Net::Location::oFono->get_modem_interface($modem_path, "ConnectionManager");
    say "Attached: ", 0+$conman->GetProperty("Attached"), # boolean
        "Bearer: ", $conman->GetProperty("Bearer"),
        "RoamingAllowed: ", 0+$conman->GetProperty("RoamingAllowed"); # boolean
    $conman->DeactivateAll(); # end of data
  }

=head1 INHERITANCE

  Net::Radio::oFono::ConnectionManager
  ISA Net::Radio::oFono::Modem
    ISA Net::Radio::oFono::Helpers::EventMgr
    DOES Net::Radio::oFono::Roles::RemoteObj
    DOES Net::Radio::oFono::Roles::Manager

=head1 METHODS

See C<ofono/doc/conman-api.txt> for valid properties and detailed
action description and possible errors.

=head2 _init($obj_path)

Initializes the modem and the manager role to handle the
I<ContextAdded> and I<ContextRemoved> signals.

=cut

sub _init
{
    my ( $self, $obj_path ) = @_;

    ( my $interface = ref($self) ) =~ s/Net::Radio::oFono:://;

    # initialize base class
    $self->Net::Radio::oFono::Modem::_init($obj_path);
    # initialize role
    $self->Net::Radio::oFono::Roles::Manager::_init();

    return;
}

sub DESTROY
{
    my $self = $_[0];

    # destroy role
    $self->Net::Radio::oFono::Roles::Manager::DESTROY();
    # initialize base class
    $self->Net::Radio::oFono::Modem::DESTROY();

    return;
}

=head2 GetContexts(;$force)

Get hash of context objects and properties.

Set the I<$force> parameter to a true value when no D-Bus main loop
is running and signal handling might be incomplete.

This method is injected by L<Net::Radio::oFono::Roles::Manager> as an alias
for L<Net::Radio::oFono::Roles::Manager/GetObjects(;$force)|GetObjects()>.

=head2 GetContext($obj_path;$force)

Returns an instance of the specified L<Net::Radio::oFono::ConnectionContext|Context>.

Set the I<$force> parameter to a true value when no D-Bus main loop
is running and signal handling might be incomplete.

This method is injected by L<Net::Radio::oFono::Roles::Manager> as an alias
for L<Net::Radio::oFono::Roles::Manager/GetObject($object_path;$force)|GetObject()>.

=head2 DeactivateAll()

Deactivates all active contexts.

=cut

sub DeactivateAll
{
    my $self = $_[0];

    $self->{remote_obj}->DeactivateAll();

    return;
}

=head2 AddContext($type)

Creates a new Primary context.  The type contains the intended purpose of
the context.

=cut

sub AddContext
{
    my ( $self, $type ) = @_;

    return $self->{remote_obj}->AddContext( dbus_string($type) );
}

=head2 RemoveContext($obj_path)

Removes a primary context.  All secondary contexts, if any, associated with
the primary context are also removed.

=cut

sub RemoveContext
{
    my ( $self, $obj_path ) = @_;

    $self->{remote_obj}->RemoveContext( dbus_object_path($obj_path) );

    return;
}

#sub RemoveAllContexts
#{
#    my ( $self ) = @_;
#
#    my @context_obj_paths = keys %{$self->{contexts}};
#    foreach my $cop (@context_obj_paths)
#    {
#	$self->{remote_obj}->RemoveContext( dbus_object_path($cop) );
#    }
#
#    return;
#}

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
