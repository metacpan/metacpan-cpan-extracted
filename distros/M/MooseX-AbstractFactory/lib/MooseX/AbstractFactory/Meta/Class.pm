package MooseX::AbstractFactory::Meta::Class;
use strict;
use warnings;
use Moose;
extends 'Moose::Meta::Class';

our $VERSION = '0.004003'; # VERSION

our $AUTHORITY = 'cpan:PENFOLD';

has implementation_roles => (
    isa => 'ArrayRef',
    is => 'rw',
    predicate => 'has_implementation_roles',
);

has implementation_class_maker => (
    isa => 'CodeRef',
    is => 'rw',
    predicate => 'has_class_maker',
);
1;

#ABSTRACT: Meta class for MooseX::AbstractFactory

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AbstractFactory::Meta::Class - Meta class for MooseX::AbstractFactory

=head1 VERSION

version 0.004003

=head1 SYNOPSIS

You shouldn't be using this on its own, but via MooseX::AbstractFactory

=head1 DESCRIPTION

Metaclass to implement an AbstractFactory as a Moose extension.

=head1 METHODS

=head2 implementation_roles

Roles each implementation class must satisfy.

=head2 has_implementation_roles

Predicate for above

=head2 implementation_class_maker

Coderef to generate a full class from a tag in the factory create() method.

=head2 has_class_maker

Predicate for above

=head1 BUGS AND LIMITATIONS

No bugs have been reported. Yet.

Please report any bugs or feature requests to C<mike@altrion.org>, or via RT.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/fleetfootmike/MX-AbstractFactory/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Mike Whitaker <mike@altrion.org>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mike Whitaker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
