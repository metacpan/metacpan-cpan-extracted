package POE::Component::Client::HTTPDeferred::Deferred;
use Any::Moose;

use POE;

has request => (
    is       => 'rw',
    isa      => 'HTTP::Request',
    weak_ref => 1,
    required => 1,
);

has client_alias => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has callbacks => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

no Any::Moose;

=head1 NAME

POE::Component::Client::HTTPDeferred::Deferred - Deferred class for POE::Component::Client::HTTPDeferred.

=head1 SEE ALSO

L<POE::Component::Client::HTTPDeferred>.

=head1 METHOD

=head2 new

    my $d = POE::Component::Client::HTTPDeferred::Deferred->new;

Create deferred object.

=head2 cancel

    $d->cancel;

Cancel HTTP Request.

=cut

sub cancel {
    my $self = shift;
    $poe_kernel->post( $self->client_alias => cancel => $self->request );

    $self;
}

=head2 callback

    $d->callback($response);

An normal response callback method. This is called when http request is successful.

=cut

sub callback {
    my ($self, $res) = @_;

    for my $cb (@{ $self->callbacks }) {
        $cb->[0]->($res) if $cb->[0];
    }
}

=head2 errback

    $d->errback($response);

An error response callback. This is called when http request is failed.

=cut

sub errback {
    my ($self, $res) = @_;

    for my $cb (@{ $self->callbacks }) {
        $cb->[1]->($res) if $cb->[1];
    }
}

=head2 addBoth

    $d->addBoth($callback);

Add $callback to both callback and errback.

This is same as following:

    $d->addCallbacks($callback, $callback);

=cut

sub addBoth {
    my ($self, $cb) = @_;
    $self->addCallbacks($cb, $cb);
}

=head2 addCallback

    $d->addCallback($callback);

Add $callback to normal callback.

=cut

sub addCallback {
    my ($self, $cb) = @_;
    $self->addCallbacks($cb, undef);
}

=head2 addCallbacks

    $d->addCallbacks( $callback, $errback );

Add $callback to normal callback, and $errback to error callback.

=cut

sub addCallbacks {
    my ($self, $cb, $eb) = @_;
    push @{ $self->callbacks }, [ $cb, $eb ];

    $self;
}

=head2 addErrback

    $d->addErrback( $errback );

Add $errback to error callback.

=cut

sub addErrback {
    my ($self, $eb) = @_;
    $self->addCallbacks(undef, $eb);
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

__PACKAGE__->meta->make_immutable;
