package Mongol;

use Moose;
use Moose::Util qw( does_role );

use Class::Load qw( load_class );

our $VERSION = '2.3';

sub map_entities {
	my ( $class, $connection, %entities ) = @_;

	while( my ( $name, $namespace ) = each( %entities ) ) {
		my $package = load_class( $name );

		if( does_role( $package, 'Mongol::Roles::Core' ) ) {
			$package->collection( $connection->get_namespace( $namespace ) );

			$package->setup()
				if( $package->can( 'setup' ) );
		}
	}
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Mongol - MongoDB ODM for Moose objects

=head1 SYNOPSIS

	package Models::Person {
		use Moose;

		extends 'Mongol::Model';

		with 'Mongol::Roles::Core';
		with 'Mongol::Roles::Pagination';

		has 'first_name' => (
			is => 'ro',
			isa => 'Str',
			required => 1,
		);

		has 'last_name' => (
			is => 'ro',
			isa => 'Str',
			required => 1,
		);

		__PACKAGE__->meta()->make_immutable();
	}

	package main {
		...

		use MongoDB;

		use Mongol;

		my $mongo = MongoDB->connect(...);

		Mongol->map_entities( $mongo,
			'Models::Person' => 'test.people',
			...
		);

		...
	}

=head1 DESCRIPTION

=head1 METHODS

=head2 map_entities

	Mongol->map_entities( $mongo_connection,
		'My::Model::Class' => 'db.collection',
		'My::Model::Other' => 'db.other_collection',
	);

Using a given MongoDB connection will automatically map a model class to a collection.
After each initialization if exists the B<setup> method on the model will be called.

=head1 AUTHOR

Tudor Marghidanu <tudor@marghidanu.com>

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=item *

L<MongoDB>

=back

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
