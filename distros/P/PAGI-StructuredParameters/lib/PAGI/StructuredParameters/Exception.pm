package PAGI::StructuredParameters::Exception;
$PAGI::StructuredParameters::Exception::VERSION = '0.001000';
use strict;
use warnings;
use overload '""' => sub { my ($self) = @_; $self->message }, fallback => 1;

# Base class for the structured-parameter exceptions. All represent malformed or
# incomplete incoming data and so map to a 400 (Bad Request).

sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
}

sub throw {
    my ($class, %args) = @_;
    die $class->new(%args);
}

sub status { 400 }

sub message { 'General error with structured parameters.' }

1;

=encoding utf8

=head1 NAME

PAGI::StructuredParameters::Exception - Base class for structured-parameter errors

=head1 DESCRIPTION

Base class for the exceptions raised by L<PAGI::StructuredParameters>. Every
subclass represents malformed or incomplete incoming data and reports an HTTP
L</status> of 400 (Bad Request). Instances stringify to their L</message>.

=head1 METHODS

=head2 new

    my $err = PAGI::StructuredParameters::Exception->new(%args);

=head2 throw

    PAGI::StructuredParameters::Exception->throw(%args);

Constructs an instance and C<die>s with it.

=head2 status

Returns C<400>.

=head2 message

Returns the human-readable error message. Overridden by subclasses.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
