package PAGI::StructuredParameters::Exception::InvalidArrayLength;
$PAGI::StructuredParameters::Exception::InvalidArrayLength::VERSION = '0.001000';
use strict;
use warnings;
use parent -norequire, 'PAGI::StructuredParameters::Exception';
use PAGI::StructuredParameters::Exception;

# Raised when array reconstruction for a key would exceed max_array_depth.

sub pointer   { my ($self) = @_; $self->{pointer} }
sub max       { my ($self) = @_; $self->{max} }
sub attempted { my ($self) = @_; $self->{attempted} }

sub message {
    my ($self) = @_;
    return "Pointer '@{[ $self->pointer ]}' has array length of "
        . "'@{[ $self->attempted ]}' but maximum is '@{[ $self->max ]}'.";
}

1;

=encoding utf8

=head1 NAME

PAGI::StructuredParameters::Exception::InvalidArrayLength - Array exceeded the allowed depth

=head1 DESCRIPTION

Raised by L<PAGI::StructuredParameters> when reconstructing an array value would
exceed C<max_array_depth>. Subclass of
L<PAGI::StructuredParameters::Exception> (HTTP status 400).

=head1 METHODS

=head2 pointer

The rule key whose array was too long.

=head2 max

The configured maximum array depth.

=head2 attempted

The number of elements the incoming data attempted.

=head2 message

    "Pointer 'children' has array length of '5000' but maximum is '1000'."

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
