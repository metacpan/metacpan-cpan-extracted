package MooseX::Constructor::AllErrors::Error::Misc;
# ABSTRACT: represents a miscellaneous error

our $VERSION = '0.025';

use Moose;
extends 'MooseX::Constructor::AllErrors::Error';
use namespace::autoclean;

has message => (
    is => 'ro', isa => 'Str',
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Constructor::AllErrors::Error::Misc - represents a miscellaneous error

=head1 VERSION

version 0.025

=head1 DESCRIPTION

This class represents an error occurring at construction time that cannot be
classified as one of the other error types.  The error message is an arbitrary
string, which describes the nature of the error.

Its creation is a little different than the other error types - it must be
explicitly created by the generating class, usually in either C<BUILDARGS> or
C<BUILD>:

    sub BUILD
    {
        my ($self, $args) = @_;

        my @errors;

        # either name *or* id is required
        push @errors, MooseX::Constructor::AllErrors::Error::Misc->new(
            message => 'Either \'name\' or \'id\' must be provided',
        ) if not defined $args->{name} and not defined $args->{id};

        ...;

        if (@errors)
        {
            my $error = MooseX::Constructor::AllErrors::Error::Constructor->new(
                caller => [ caller( Class::MOP::class_of($self)->is_immutable ? 2 : 4) ],
            );
            $error->add_error($_) foreach @errors;
            die $error;
        }
    }

This code is a little long and unwieldy; it is likely that a shortcut will soon
be added; it has been suggested that support for a VALIDATE sub be added, which
is automatically called at construction time before BUILD, to perform
validations with no side effect. Stay tuned to upcoming releases!

=head1 METHODS

=head2 message

Returns a human-readable error message for this error.

=head1 SEE ALSO

L<Moose>

=head1 AUTHOR

Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
