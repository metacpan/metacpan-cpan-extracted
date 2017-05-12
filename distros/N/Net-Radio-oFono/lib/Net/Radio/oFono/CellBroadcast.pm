package Net::Radio::oFono::CellBroadcast;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono::CellBroadcast - access Modem object's CellBroadcast interface

=cut

our $VERSION = '0.001';

use Net::DBus qw(:typing);

use base qw(Net::Radio::oFono::Modem);

=head1 SYNOPSIS

  my $oFono = Net::Location::oFono->new();
  my @modems = Net::Location::oFono->get_modems();
  foreach my $modem_path (@modems) {
    my $cellbc = Net::Location::oFono->get_modem_interface($modem_path, "CellBroadcast");
    say "Powered: ", $cellbc->GetProperty("Powered"),
        "Topics: ", $cellbc->GetProperty("Topics");
  }

=head1 INHERITANCE

  Net::Radio::oFono::CellBroadcast
  ISA Net::Radio::oFono::Modem
    ISA Net::Radio::oFono::Helpers::EventMgr
    DOES Net::Radio::oFono::Roles::RemoteObj
    DOES Net::Radio::oFono::Roles::Properties

=head1 METHODS

See C<ofono/doc/cell-broadcast-api.txt> for valid properties and detailed
action description and possible errors.

=head2 _init($obj_path)

Connects on D-Bus signals I<IncomingBroadcast> and I<EmergencyBroadcast> after
base class is initialized.

=cut

sub _init
{
    my ( $self, $obj_path ) = @_;

    ( my $interface = ref($self) ) =~ s/Net::Radio::oFono:://;

    # initialize base class
    $self->Net::Radio::oFono::Modem::_init($obj_path);

    my $on_incoming_broadcast = sub { return $self->onIncomingBroadcast(@_); };
    $self->{sig_incoming_broadcast} =
      $self->{remote_obj}->connect_to_signal( "IncomingBroadcast", $on_incoming_broadcast );

    my $on_emergency_broadcast = sub { return $self->onEmergencyBroadcast(@_); };
    $self->{sig_emergency_broadcast} =
      $self->{remote_obj}->connect_to_signal( "EmergencyBroadcast", $on_emergency_broadcast );

    return;
}

sub DESTROY
{
    my $self = $_[0];

    defined( $self->{remote_obj} )
      and $self->{remote_obj}
      ->disconnect_from_signal( "IncomingBroadcast", $self->{sig_incoming_broadcast} );
    defined( $self->{remote_obj} )
      and $self->{remote_obj}
      ->disconnect_from_signal( "EmergencyBroadcast", $self->{sig_emergency_broadcast} );

    # initialize base class
    $self->Net::Radio::oFono::Modem::DESTROY();

    return;
}

sub _extra_events { return qw(ON_INCOMING_BROADCAST ON_EMERGENCY_BROADCAST); }

=head2 onIncomingBroadcast

Called when D-Bus signal I<IncomingBroadcast> is received.

Generates event C<ON_INCOMING_BROADCAST> with arguments C<< $text, $topic >>.

=cut

sub onIncomingBroadcast
{
    my ( $self, $text, $topic ) = @_;
    $self->trigger_event( "ON_INCOMING_BROADCAST", [ $text, $topic ] );
    return;
}

=head2 onEmergencyBroadcast

Called when D-Bus signal I<EmergencyBroadcast> is received.

Generates event C<ON_EMERGENCY_BROADCAST> with arguments C<< $text, $topic >>.

=cut

sub onEmergencyBroadcast
{
    my ( $self, $text, $topic ) = @_;
    $self->trigger_event( "ON_EMERGENCY_BROADCAST", [ $text, $topic ] );
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
