package MooseX::AbstractFactory::Role;
use strict;
use warnings;
use Moose::Role;

use Moose::Autobox;
use Module::Runtime qw( use_package_optimistically );
use Try::Tiny;

our $VERSION = '0.004003'; # VERSION

our $AUTHORITY = 'cpan:PENFOLD';

has _options        => (is => 'ro', isa => 'ArrayRef[Any]');
has _implementation => (is => 'ro', isa => 'Str');

sub create {
	my ($class, $impl, @impl_args) = @_;

	if (defined $impl) {
		my $factory
			= $class->new({
				_implementation => $impl,
				_options => [ @impl_args ]
			});

		my $iclass
			= $factory->_get_implementation_class(
				$factory->_implementation()
			);

		# pull in our implementation class
		$factory->_validate_implementation_class($iclass);

		my $iconstructor = $iclass->meta->constructor_name;

		my $implementation
			= $iclass->$iconstructor(
				@{ $factory->_options }
			);

		# TODO - should we sneak a factory attr onto the metaclass?
		return $implementation;
	}
	else {
		confess('No implementation provided');
	}
}

sub _get_implementation_class {
	my ($self, $impl) = @_;

	my $class = blessed $self;
	if ($self->meta->has_class_maker) {
		return $self->meta->implementation_class_maker->($impl);
	}
	else {
		return $class . "::$impl";
	}
}

sub _validate_implementation_class {
	my ($self, $iclass) = @_;

	try {
		# can we load the class?
		use_package_optimistically($iclass); # may die if user really stuffed up _get_implementation_class()

		if ($self->meta->has_implementation_roles) {
			my $roles = $self->meta->implementation_roles();

			# create an anon class that's a subclass of it
			my $anon = Moose::Meta::Class->create_anon_class();

			# make it a subclass of the implementation
			$anon->superclasses($iclass);

			# Lifted from MooseX::Recipe::Builder->_build_anon_meta()

			# load our role classes
			$roles->map( sub { use_package_optimistically($_); } );

			# apply roles to anon class
			if (scalar @{$roles} == 1) {
				$roles->[0]->meta->apply($anon);
			}
			else {
				Moose::Meta::Role->combine($roles->map(sub { $_->meta; } ))->apply($anon);
			}
		}
	}
	catch {
		confess "Invalid implementation class $iclass: $_";
	};

	return;
}

1;
# ABSTRACT: AbstractFactory behaviour as a Moose extension

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AbstractFactory::Role - AbstractFactory behaviour as a Moose extension

=head1 VERSION

version 0.004003

=head1 SYNOPSIS

You shouldn't be using this on its own, but via MooseX::AbstractFactory

=head1 DESCRIPTION

Role to implement an AbstractFactory as a Moose extension.

=head1 METHODS

=head2 create()

Returns an instance of the requested implementation.

	use MooseX::AbstractFactory;

	my $imp = My::Factory->create(
		'Implementation',
		{ connection => 'Type1' },
	);

=head2 _validate_implementation_class()

Optional: it provides the methods defined in _roles().

This can be overridden by a factory class definition if required: for example

	sub _validate_implementation_class {
		my $self = shift;
		return 1; # all implementation classes are valid :)
	}

=head2 _get_implementation_class()

By default, the factory figures out the class of the implementation requested
by prepending the factory class itself, so for example

	my $imp = My::Factory->new(
		implementation => 'Implementation')

will return an object of class My::Factory::Implementation.

This can be overridden in the factory class by redefining the
_get_implementation_class() method, for example:

	sub _get_implementation_class {
		my ($self, $class) = @_;
		return "My::ImplementationClasses::$class";
	}

=head1 BUGS AND LIMITATIONS

No bugs have been reported. Yet.

Please report any bugs or feature requests to C<mike@altrion.org>, or via RT.

=head1 ACKNOWLEDGMENTS

Thanks to Matt Trout for some of the ideas for the code in
_validate_implementation_class.

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
