package MooseX::AbstractFactory;
use strict;
use warnings;
use Moose ();

use Moose::Exporter;
use MooseX::AbstractFactory::Meta::Class;

our $VERSION = '0.004003'; # VERSION

our $AUTHORITY = 'cpan:PENFOLD';

# syntactic sugar for various tricks

Moose::Exporter->setup_import_methods(
    with_caller => [ 'implementation_does', 'implementation_class_via' ],
    also => 'Moose',
);

sub implementation_does {
    my ($caller, @args) = @_;

    my @roles = ref $args[0] eq 'ARRAY' ? @{ $args[0] } : @args;

    $caller->meta->implementation_roles(\@roles);
    return;
}

sub implementation_class_via {
    my ($caller, $code) = @_;

    $caller->meta->implementation_class_maker($code);
    return;
}

sub init_meta {
    my ( $self, %options ) = @_;

    Moose->init_meta( %options, metaclass => 'MooseX::AbstractFactory::Meta::Class' );

    Moose::Util::MetaRole::apply_base_class_roles(
        for_class => $options{for_class},
        roles     => ['MooseX::AbstractFactory::Role'],
    );

    return $options{for_class}->meta();
}

1;

#ABSTRACT: AbstractFactory behaviour as a Moose extension

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AbstractFactory - AbstractFactory behaviour as a Moose extension

=head1 VERSION

version 0.004003

=head1 SYNOPSIS

	package My::Factory;
	use MooseX::AbstractFactory;

	# optional role(s) that define what the implementations should implement

	implementation_does [ qw( My::Factory::Implementation::Requires ) ];
	implementation_class_via sub { 'My::Implementation::' . shift };

	# -------------------------------------------------------------
	package My::Implementation::One;
	use Moose;

	has connection => (is => 'ro', isa => 'Str');

	sub tweak_connection {
		...
	}


	# -------------------------------------------------------------
	package My::Factory::Implementation::Requires;
	use Moose::Role;
	requires 'tweak_connection';


	# -------------------------------------------------------------
	package main;
	use My::Factory;

	my $imp = My::Factory->create('One',
		{ connection => 'Type1' },
	);

=head1 DESCRIPTION

Implements an AbstractFactory as a Moose extension

=head1 METHODS

=head2 create()

Returns an instance of the requested implementation.

    use MooseX::AbstractFactory;

	my $imp = My::Factory->create(
		'Implementation',
		{ connection => 'Type1' },
	);

=head2 implementation_does

Syntactic sugar to define a list of roles each implementation must consume.

=head2 implementation_class_via

Syntactic sugar to provide a sub to generate the implementation class name:
e.g.:

    use MooseX::AbstractFactory;
    implementation_class_via sub { 'My::Implementation::' . shift };

and then

    my $imp = My::Factory->create("ClassA");

    # $imp->isa "My::Implementation::ClassA"

The default behaviour is to prepend the factory class name, so in the above
example (without the implementation_class_via) the implementation class would
be "My::Factory::ClassA".

=head2 init_meta

Overrides L<Moose>'s C<init_meta> and applies
L<MooseX::AbstractFactory::Role>.

=head1 DIAGNOSTICS

=over

=item C<< No implementation provided >>

If the factory class's new() method doesn't get an implementation passed,
then it will die with the above error.

=item C<< Invalid implementation class %s: %s" >>

The implementation passed to the factory class mapped to a class that doesn't exist.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/fleetfootmike/MX-AbstractFactory/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CONTRIBUTOR

Zoffix Znet <cpan@zoffix.com>

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
