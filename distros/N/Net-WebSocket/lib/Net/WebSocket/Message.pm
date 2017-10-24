package Net::WebSocket::Message;

use strict;
use warnings;

use Call::Context ();

sub new {
    if (!$_[1]->isa('Net::WebSocket::Frame')) {
        die( (caller 0)[3] . ' needs at least one Net::WebSocket::Frame object!' );
    }

    return bless \@_, shift;
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

#----------------------------------------------------------------------
# Static function that auto-loads the actual message class.

sub create_from_frames {
    my $type = $_[0]->get_type();

    my $class = __PACKAGE__ . "::$type";
    if (!$class->can('new')) {
        Module::Load::load($class);
    }

    return $class->new(@_);
}

1;
