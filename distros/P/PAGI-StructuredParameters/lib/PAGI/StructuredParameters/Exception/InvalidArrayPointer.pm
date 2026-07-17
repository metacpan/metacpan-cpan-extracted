package PAGI::StructuredParameters::Exception::InvalidArrayPointer;
$PAGI::StructuredParameters::Exception::InvalidArrayPointer::VERSION = '0.001001';
use strict;
use warnings;
use parent -norequire, 'PAGI::StructuredParameters::Exception';
use PAGI::StructuredParameters::Exception;

# Raised when nested data names an array rule but the value at that pointer is
# not an arrayref.

sub pointer { my ($self) = @_; $self->{pointer} }

sub message {
    my ($self) = @_;
    return "Pointer '@{[ $self->pointer ]}' is not an array.";
}

1;

=encoding utf8

=head1 NAME

PAGI::StructuredParameters::Exception::InvalidArrayPointer - Expected an array but found another shape

=head1 DESCRIPTION

Raised by L<PAGI::StructuredParameters> when a rule expects an array at a given
pointer in nested body data (C<src =E<gt> 'data'>) but the value there is not an
arrayref. Subclass of L<PAGI::StructuredParameters::Exception> (HTTP status 400).

=head1 METHODS

=head2 pointer

The dotted key path whose value was not an array.

=head2 message

    "Pointer 'cards' is not an array."

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
