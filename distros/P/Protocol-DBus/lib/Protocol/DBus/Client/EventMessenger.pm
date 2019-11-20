package Protocol::DBus::Client::EventMessenger;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Client::EventMessenger - Messenger for
L<Protocol::DBus::Client::EventBase> subclasses.

=head1 DESCRIPTION

This module is instantiated automatically by
L<Protocol::DBus::Client::EventBase>.

=head1 INSTANCE METHODS

This class provides the following methods that provide the same interfaces
as their counterparts in L<Protocol::DBus::Peer>:

=over

=item * C<send_call()>

=item * C<send_return()>

=item * C<send_error()>

=item * C<send_signal()>

=back

=cut

sub send_call { _wrap_send( 'send_call', @_ ) }

sub send_return { _wrap_send( 'send_return', @_ ) }

sub send_error { _wrap_send( 'send_error', @_ ) }

sub send_signal { _wrap_send( 'send_signal', @_ ) }

# Undocumented
sub new {
    my ($class, $dbus, $post_send_cr) = @_;

    return bless [$dbus, $post_send_cr], $class;
}

sub _wrap_send {
    my ($fn, $self) = @_;

    my $ret = $self->[0]->$fn( @_[2 .. $#_] );

    $self->[1]->();

    return $ret;
}

1;
