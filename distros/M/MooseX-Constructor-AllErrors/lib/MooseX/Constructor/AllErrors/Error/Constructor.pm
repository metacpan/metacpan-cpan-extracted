package MooseX::Constructor::AllErrors::Error::Constructor;
# ABSTRACT: error class for MooseX::Constructor::AllErrors

our $VERSION = '0.025';

use Moose;
use namespace::autoclean 0.16;  # overload handling

has errors => (
    isa => 'ArrayRef[MooseX::Constructor::AllErrors::Error]',
    traits => ['Array'],
    handles => {
        errors => 'elements',
        has_errors => 'count',
        add_error => 'push',
    },
    lazy => 1,
    default => sub { [] },
);

# FIXME - this should be calculated automatically, in a default sub.
# But manually counting the number of stack frames involved is fragile and
# prone to error as Moose guts change. We need to find a better way!
has caller => (
    is => 'ro',
    isa => 'ArrayRef',
    required => 1,
);

sub _errors_by_type {
    my ($self, $type) = @_;
    return [ grep {
        $_->isa("MooseX::Constructor::AllErrors::Error::$type")
    } $self->errors ];
}

has missing => (
    isa => 'ArrayRef[MooseX::Constructor::AllErrors::Error::Required]',
    traits => ['Array'],
    handles => { missing => 'elements' },
    lazy => 1,
    default => sub { shift->_errors_by_type('Required') },
);

has invalid => (
    isa => 'ArrayRef[MooseX::Constructor::AllErrors::Error::TypeConstraint]',
    traits => ['Array'],
    handles => { invalid => 'elements' },
    lazy => 1,
    default => sub { shift->_errors_by_type('TypeConstraint') },
);

has misc => (
    isa => 'ArrayRef[MooseX::Constructor::AllErrors::Error::Misc]',
    traits => ['Array'],
    handles => { misc => 'elements' },
    lazy => 1,
    default => sub { shift->_errors_by_type('Misc') },
);

sub message {
    my $self = shift;
    confess "$self->message called without any errors"
        unless $self->has_errors;
    return ($self->errors)[0]->message;
}

sub stringify {
    my $self = shift;
    return '' unless $self->has_errors;
    return sprintf '%s at %s line %d',
        $self->message,
        $self->caller->[1], $self->caller->[2];
}

use overload (
    q{""} => 'stringify',
    fallback => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Constructor::AllErrors::Error::Constructor - error class for MooseX::Constructor::AllErrors

=head1 VERSION

version 0.025

=head1 DESCRIPTION

C<$@> will contain an instance of this class when
L<MooseX::Constructor::AllErrors> throws an exception during object
construction.

=head1 METHODS

=head2 has_errors

True if there are any errors.

=head2 add_error

Push a new error to the list (should be an
L<MooseX::Constructor::AllErrors::Error> object).

=head2 message

Returns the first error message found.

=head2 stringify

Returns the first error message found, along with caller information (filename
and line number).

=head2 errors

Returns a list of L<MooseX::Constructor::AllErrors::Error> objects representing
each error that was found.

=head2 missing

Returns a list of L<MooseX::Constructor::AllErrors::Error::Required> objects
representing each missing argument error that was found.

=head2 invalid

Returns a list of L<MooseX::Constructor::AllErrors::Error::TypeConstraint>
objects representing each type constraint error that was found.

=head2 misc

Returns a list of L<MooseX::Constructor::AllErrors::Error::Misc>
objects representing each miscellaneous error that was found.

=head1 SEE ALSO

L<Moose>

=head1 AUTHOR

Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
