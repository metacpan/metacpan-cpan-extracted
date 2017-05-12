package MooseX::Role::UpdateAttributes;

use Moose::Role;
use Moose::Util qw( find_meta );

our $VERSION = '1.1';

sub set_attributes {
	my ( $self, %data ) = @_;

	my $meta = find_meta( $self );

	foreach my $name ( keys( %data ) ) {
		my $attribute = $meta->find_attribute_by_name( $name );
		next()
			unless( defined( $attribute ) );

		my $method = $attribute->get_write_method();
		next()
			unless( defined( $method ) );

		$self->$method( $data{ $name } );
	}

	return $self;
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

MooseX::Role::UpdateAttributes - Update attribute values

=head1 SYNOPSIS

	package Models::Person {
		use Moose;

		with 'MooseX::Role::UpdateAttributes';

		has 'name' => (
			is => 'ro',
			isa => 'Str',
			required => 1
		);

		has 'age' => (
			is => 'rw',
			isa => 'Int',
			required => 1
		);

		__PACKAGE__->meta()->make_immutable();
	}

	package main {

		my $person = Models::Person->new(
			{
				name => 'Bruce Wayne',
				age => 30
			}
		);

		$person->set_attributes(
			name => 'Wally West',
			age => 22,
			dummy => 100,
		);

		$person->name(); # Still 'Bruce Wayne' because the name attribute is read-only

		$person->age(); # Is now set to 22
	}


=head1 DESCRIPTION

This role allow for setting the values for setting values on multiple writable accesors at once.

=head1 METHODS

=head2 set_attributes

	$instance->set_attributes( %data );

=head1 AUTHOR

Tudor Marghidanu <tudor@marghidanu.com>

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=back

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
