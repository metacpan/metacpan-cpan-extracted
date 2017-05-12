package Net::Radio::oFono::SimManager;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono::SimManager - access Modem object's SimManager interface

=cut

our $VERSION = '0.001';

use Carp qw/croak/;
use Net::DBus qw(:typing);

use base qw(Net::Radio::oFono::Modem);

=head1 SYNOPSIS

  my $oFono = Net::Location::oFono->new();
  my @modems = Net::Location::oFono->get_modems();
  foreach my $modem_path (@modems) {
    my $simmgr = Net::Location::oFono->get_modem_interface($modem_path, "SimManager");
    $simmgr->GetProperty("SubscriberIdentity") eq $cfg{IMSI} # identify right one
      and $simmgr->GetProperty("PinRequired") eq "pin" # do not enter when not wanted
      and $simmgr->EnterPin("pin", "1234"); # enter pin code
  }

=head1 INHERITANCE

  Net::Radio::oFono::SimManager
  ISA Net::Radio::oFono::Modem
    ISA Net::Radio::oFono::Helpers::EventMgr
    DOES Net::Radio::oFono::Roles::RemoteObj
    DOES Net::Radio::oFono::Roles::Properties

=head1 METHODS

See C<ofono/doc/sim-api.txt> for valid pin types and detailed
action description and possible errors.

=cut

my @valid_pin_types = (
                        qw(none pin phone firstphone pin2 network netsub service corp puk),
                        qw(firstphonepuk puk2 networkpuk netsubpuk servicepuk corppuk)
                      );

=head2 ChangePin($pintype,$oldpin,$newpin)

Changes the appropriate pin type.

=cut

sub ChangePin
{
    my ( $self, $pin_type, $oldpin, $newpin ) = @_;

    $pin_type ~~ @valid_pin_types
      or croak(   "Invalid PIN type: '"
                . $pin_type
                . "'. Valid are: '"
                . join( "', '", @valid_pin_types )
                . "'." );

    $self->{remote_obj}
      ->ChangePin( dbus_string($pin_type), dbus_string($oldpin), dbus_string($newpin) );

    return;
}

=head2 EnterPin($pintype,$pin)

Enters the currently pending pin.  The type value must match the pin type
being asked in the PinRequired property.

=cut

sub EnterPin
{
    my ( $self, $pin_type, $pin ) = @_;

    $pin_type ~~ @valid_pin_types
      or croak(   "Invalid PIN type: '"
                . $pin_type
                . "'. Valid are: '"
                . join( "', '", @valid_pin_types )
                . "'." );

    $self->{remote_obj}->EnterPin( dbus_string($pin_type), dbus_string($pin) );

    return;
}

=head2 ResetPin($pintype,$puk,$pin)

Provides the unblock key to the modem and if correct resets the pin to
the new value of pin.

=cut

sub ResetPin
{
    my ( $self, $pin_type, $puk, $pin ) = @_;

    $pin_type ~~ @valid_pin_types
      or croak(   "Invalid PIN type: '"
                . $pin_type
                . "'. Valid are: '"
                . join( "', '", @valid_pin_types )
                . "'." );

    $self->{remote_obj}->ResetPin( dbus_string($pin_type), dbus_string($puk), dbus_string($pin) );

    return;
}

=head2 LockPin($pintype,$pin)

Activates the lock for the particular pin type.

=cut

sub LockPin
{
    my ( $self, $pin_type, $pin ) = @_;

    $pin_type ~~ @valid_pin_types
      or croak(   "Invalid PIN type: '"
                . $pin_type
                . "'. Valid are: '"
                . join( "', '", @valid_pin_types )
                . "'." );

    $self->{remote_obj}->LockPin( dbus_string($pin_type), dbus_string($pin) );

    return;
}

=head2 UnlockPin($pintype,$pin)

Deactivates the lock for the particular pin type.

=cut

sub UnlockPin
{
    my ( $self, $pin_type, $pin ) = @_;

    $pin_type ~~ @valid_pin_types
      or croak(   "Invalid PIN type: '"
                . $pin_type
                . "'. Valid are: '"
                . join( "', '", @valid_pin_types )
                . "'." );

    $self->{remote_obj}->UnlockPin( dbus_string($pin_type), dbus_string($pin) );

    return;
}

=head2 GetIcon($id)

Obtain the icon given by id.  Only ids greater than 1 are valid.
XPM format is currently used to return the icon data.

=cut

sub GetIcon
{
    my ( $self, $id ) = @_;

    return $self->{remote_obj}->getIcon($id);
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
