package Net::WebSocket::Message;

use strict;
use warnings;

use Call::Context ();

use Net::WebSocket::Constants ();

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self) = shift;

    return if substr( $AUTOLOAD, -8 ) eq ':DESTROY';

    my $last_colon_idx = rindex( $AUTOLOAD, ':' );
    my $method = substr( $AUTOLOAD, 1 + $last_colon_idx );

    #Figure out what type this is, and re-bless.
    if (ref($self) eq __PACKAGE__) {
        my $type = $self->[0]->get_type();

        my $class = __PACKAGE__ . "::$type";
        if (!$class->can('new')) {
            Module::Load::load($class);
        }

        bless $self, $class;

        if ($self->can($method)) {
            return $self->$method(@_);
        }
    }

    die( "$self has no method “$method”!" );
}

#----------------------------------------------------------------------

sub create_from_frames {
    return bless \@_, __PACKAGE__;
}

sub get_frames {
    my ($self) = @_;

    Call::Context::must_be_list();

    return @$self;
}

sub get_payload {
    my ($self) = @_;

    return join( q<>, map { $_->get_payload() } @$self );
}

sub to_bytes {
    my ($self) = @_;

    return join( q<>, map { $_->to_bytes() } @$self );
}

1;
