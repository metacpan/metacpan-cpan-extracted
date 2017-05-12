package Net::Radio::oFono::MessageManager;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono::MessageManager - provide MessageManager interface for Modem objects

=cut

use Net::DBus qw(:typing);

require Net::Radio::oFono::Message;

use Net::Radio::oFono::Roles::Manager qw(Message);
use base qw(Net::Radio::oFono::Modem Net::Radio::oFono::Roles::Manager);

=head1 SYNOPSIS

  my $oFono = Net::Location::oFono->new();
  my @modems = Net::Location::oFono->get_modems();
  # show default network information
  foreach my $modem_path (@modems) {
    my $msgman = Net::Location::oFono->get_modem_interface($modem_path, "MessageManager");
    say "Alphabet: ", $msgman->GetProperty("Alphabet");
    $msgman->SendMessage("911", "Wanna have some fun?");
  }

=head1 INHERITANCE

  Net::Radio::oFono::MessageManager
  ISA Net::Radio::oFono::Modem
    ISA Net::Radio::oFono::Helpers::EventMgr
    DOES Net::Radio::oFono::Roles::RemoteObj
    DOES Net::Radio::oFono::Roles::Manager

=head1 METHODS

See C<ofono/doc/messagemanager-api.txt> for valid properties and detailed
action description and possible errors.

=head2 _init($obj_path)

Initializes the modem and the manager role to handle the
I<MessageAdded> and I<MessageRemoved> signals. After it
handlers for the D-Bus signals I<ImmediateMessage> and
I<IncomingMessage> are added.

=cut

sub _init
{
    my ( $self, $obj_path ) = @_;

    ( my $interface = ref($self) ) =~ s/Net::Radio::oFono:://;

    # initialize base class
    $self->Net::Radio::oFono::Modem::_init($obj_path);
    # initialize role
    $self->Net::Radio::oFono::Roles::Manager::_init();

    my $on_incoming_message = sub { return $self->onIncomingMessage(@_); };
    $self->{sig_incoming_message} =
      $self->{remote_obj}->connect_to_signal( "IncomingMessage", $on_incoming_message );

    my $on_immediate_message = sub { return $self->onImmediateMessage(@_); };
    $self->{sig_immediate_message} =
      $self->{remote_obj}->connect_to_signal( "ImmediateMessage", $on_immediate_message );

    return;
}

sub DESTROY
{
    my $self = $_[0];

    defined( $self->{remote_obj} )
      and $self->{remote_obj}
      ->disconnect_from_signal( "IncomingMessage", $self->{sig_incoming_message} );
    defined( $self->{remote_obj} )
      and $self->{remote_obj}
      ->disconnect_from_signal( "ImmediateMessage", $self->{sig_immediate_message} );

    # destroy role
    $self->Net::Radio::oFono::Roles::Manager::DESTROY();
    # initialize base class
    $self->Net::Radio::oFono::Modem::DESTROY();

    return;
}

sub _extra_events { return qw(ON_IMMEDIATE_MESSAGE ON_INCOMING_MESSAGE); }

=head2 GetMessages(;$force)

Get an hash of message object paths and properties that represents the
currently pending messages.

Set the I<$force> parameter to a true value when no D-Bus main loop
is running and signal handling might be incomplete.

This method is injected by L<Net::Radio::oFono::Roles::Manager> as an alias
for L<Net::Radio::oFono::Roles::Manager/GetObjects(;$force)|GetObjects()>.

=head2 GetMessage($obj_path;$force)

Returns an instance of the specified L<Net::Radio::oFono::Message|Message>.

Set the I<$force> parameter to a true value when no D-Bus main loop
is running and signal handling might be incomplete.

This method is injected by L<Net::Radio::oFono::Roles::Manager> as an alias
for L<Net::Radio::oFono::Roles::Manager/GetObject($object_path;$force)|GetObject()>.

=head2 SendMessage($to,$text)

Send the message in text to the number in to.  If the message could be
queued successfully, this method returns an object path to the created
Message object.

=cut

sub SendMessage
{
    my ( $self, $to, $text ) = @_;

    $self->{remote_obj}->SendMessage( dbus_string($to), dbus_string($text) );

    return;
}

=head2 onImmediateMessage

Called when D-Bus signal I<ImmediateMessage> is received.

Generates event C<ON_IMMEDIATE_MESSAGE> with arguments C<< $message, $info >>.
$info has Sender, LocalSentTime, and SentTime information.

=cut

sub onImmediateMessage
{
    my ( $self, $message, $info ) = @_;

    $self->trigger_event( "ON_IMMEDIATE_MESSAGE", [ $message, $info ] );

    return;
}

=head2 onIncomingMessage

Called when D-Bus signal I<IncomingMessage> is received.

Generates event C<ON_INCOMING_MESSAGE> with arguments C<< $message, $info >>.
$info has Sender, LocalSentTime, and SentTime information.

=cut

sub onIncomingMessage
{
    my ( $self, $message, $info ) = @_;

    $self->trigger_event( "ON_INCOMING_MESSAGE", [ $message, $info ] );

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
