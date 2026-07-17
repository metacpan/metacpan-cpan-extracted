package PAGI::StructuredParameters::Exception::MissingParameter;
$PAGI::StructuredParameters::Exception::MissingParameter::VERSION = '0.001001';
use strict;
use warnings;
use parent -norequire, 'PAGI::StructuredParameters::Exception';
use PAGI::StructuredParameters::Exception;

# Raised by 'required' when one or more required keys are absent. 'missing' holds
# the full list of missing dotted key paths; 'param' is the first, for a concise
# single-line message.

sub param { my ($self) = @_; $self->{param} // ($self->{missing} // [])->[0] }

sub missing { my ($self) = @_; $self->{missing} // [defined $self->{param} ? $self->{param} : ()] }

sub message {
    my ($self) = @_;
    return "Required parameter '@{[ $self->param ]}' is missing.";
}

1;

=encoding utf8

=head1 NAME

PAGI::StructuredParameters::Exception::MissingParameter - A required parameter was absent

=head1 DESCRIPTION

Raised by L<PAGI::StructuredParameters/required> when one or more required keys
are absent from the incoming parameters. Subclass of
L<PAGI::StructuredParameters::Exception> (HTTP status 400).

=head1 METHODS

=head2 param

The first missing key path (e.g. C<'person.name'>).

=head2 missing

An arrayref of all missing key paths detected during the parse.

=head2 message

    "Required parameter 'person.name' is missing."

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
