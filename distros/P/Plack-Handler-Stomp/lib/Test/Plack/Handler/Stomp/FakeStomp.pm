package Test::Plack::Handler::Stomp::FakeStomp;
$Test::Plack::Handler::Stomp::FakeStomp::VERSION = '1.15';
{
  $Test::Plack::Handler::Stomp::FakeStomp::DIST = 'Plack-Handler-Stomp';
}
use strict;
use warnings;
use parent 'Net::Stomp';
use Net::Stomp::Frame;

# ABSTRACT: subclass of L<Net::Stomp>, half-mocked for testing


sub _get_connection {
    return 1;
}

sub current_host {
    return 0;
}


sub new {
    my $class = shift;
    my $callbacks = shift;
    $callbacks->{new}->(@_);
    my $self = $class->SUPER::new(@_);
    $self->{__fakestomp__callbacks} = $callbacks;
    return $self;
}


sub connect {
    my ( $self, $conf ) = @_;

    $self->{__fakestomp__callbacks}{connect}->($conf);
    return Net::Stomp::Frame->new({
        command => 'CONNECTED',
        headers => {
            session => 'ID:foo',
        },
        body => '',
    });
}


sub disconnect {
    my ( $self ) = @_;

    $self->{__fakestomp__callbacks}{disconnect}->();
    return 1;
}


sub can_read { return 1 }
sub _connected { return 1 }



sub subscribe {
    my ( $self, $conf ) = @_;

    $self->{__fakestomp__callbacks}{subscribe}->($conf);
    return 1;
}


sub unsubscribe {
    my ( $self, $conf ) = @_;

    $self->{__fakestomp__callbacks}{unsubscribe}->($conf);
    return 1;
}


sub send_frame {
    my ( $self, $frame ) = @_;

    $self->{__fakestomp__callbacks}{send_frame}->($frame);
}


sub receive_frame {
    my ( $self, $conf ) = @_;

    return $self->{__fakestomp__callbacks}{receive_frame}->($conf);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Plack::Handler::Stomp::FakeStomp - subclass of L<Net::Stomp>, half-mocked for testing

=head1 VERSION

version 1.15

=head1 DESCRIPTION

This class is designed to be used in conjuction with
L<Test::Plack::Handler::Stomp>. It expects a set of callbacks that
will be invoked whenever a method is called. It also does not talk to
the network at all.

=head1 METHODS

=head2 C<new>

  my $stomp = Test::Plack::Handler::Stomp::FakeStomp->new({
    new => sub { $self->queue_constructor_call(shift) },
    connect => sub { $self->queue_connection_call(shift) },
    disconnect => sub { $self->queue_disconnection_call(shift) },
    subscribe => sub { $self->queue_subscription_call(shift) },
    unsubscribe => sub { $self->queue_unsubscription_call(shift) },
    send_frame => sub { $self->queue_sent_frame(shift) },
    receive_frame => sub { $self->next_frame_to_receive() },
  },$params);

The first parameter must be a hashref with all those keys pointing to
coderefs. Each coderef will be invoked when the corresponding method
is called, and will receive all the parameters of that call (minus the
invocant).

The parameters (to this C<new>) after the first will be passed to
L<Net::Stomp>'s C<new>.

The C<new> callback I<is> called by this method, just before
delegating to the inherited constructor. This callback does not
receive the callback hashref (i.e. it receives C<< @_[2..*] >>.

=head2 C<connect>

Calls the C<connect> callback, and returns 1.

=head2 C<disconnect>

Calls the C<disconnect> callback, and returns 1.

=head2 C<can_read>

Returns 1.

=head2 C<subscribe>

Calls the C<subscribe> callback, and returns 1.

=head2 C<unsubscribe>

Calls the C<unsubscribe> callback, and returns 1.

=head2 C<send_frame>

Calls the C<send_frame> callback.

=head2 C<receive_frame>

Calls the C<receive_frame> callback, and returns whatever that
returned.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
