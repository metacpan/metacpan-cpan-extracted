package Net::Flotum::Object::Charge;
use common::sense;
use Moo;
use namespace::clean;
use MooX::late;
use Carp;

has flotum => (
    is       => "ro",
    weak_ref => 1,
    required => 1,
);

has id => (
    is       => "rw",
    isa      => "Str",
    required => 1,
);

has customer => (
    is       => "rw",
    isa      => "Net::Flotum::Object::Customer",
    weak_ref => 1,
);

sub payment {
    my $self = shift;

    return $self->flotum->_payment_charge( @_, charge => $self );
}

sub capture {
    my $self = shift;

    return $self->flotum->_capture_charge( @_, charge => $self );
}

sub refund {
    my $self = shift;

    return $self->flotum->_refund_charge( @_, charge => $self );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Net::Flotum::Object::Charge - Flotum charge object representation

=head1 SYNOPSIS

Please read L<Net::Flotum>

=head1 AUTHOR

Junior Moraes L<juniorfvox@gmail.com|mailto:juniorfvox@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
