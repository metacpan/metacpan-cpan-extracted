package Mongol::Roles::Core;

use Moose::Role;

use MooseX::ClassAttribute;

use Mongol::Cursor;

use Scalar::Util qw( blessed );

requires 'pack';
requires 'unpack';

class_has 'collection' => (
	is => 'rw',
	isa => 'Maybe[MongoDB::Collection]',
	default => undef,
);

has 'id' => (
	is => 'rw',
	isa => 'Maybe[MongoDB::OID|Str|Num]',
	lazy_build => 1,
);

sub _build_id { undef }

sub find {
	my ( $class, $query, $options ) = @_;

	die( 'No collection defined!' )
		unless( defined( $class->collection() ) );

	my $result = $class->collection()
		->find( $query, $options )
		->result();

	return Mongol::Cursor->new(
		{
			type => $class,
			result => $result,
		}
	);
}

sub find_one {
	my ( $class, $query, $options ) = @_;

	die( 'No collection defined!' )
		unless( defined( $class->collection() ) );

	my $document = $class->collection()
		->find_one( $query, {}, $options );

	return defined( $document ) ?
		$class->to_object( $document ) :
		undef;
}

sub retrieve {
	my ( $class, $id ) = @_;

	die( 'No identifier provided!' )
		unless( defined( $id ) );

	return $class->find_one( { _id => $id } );
}

sub count {
	my ( $class, $query, $options ) = @_;

	die( 'No collection defined!' )
		unless( defined( $class->collection() ) );

	return $class->collection()
		->count( $query, $options );
}

sub exists {
	my ( $class, $id ) = @_;

	return $class->count( { _id => $id } );
}

sub update {
	my ( $class, $query, $update, $options ) = @_;

	die( 'No collection defined!' )
		unless( defined( $class->collection() ) );

	my $result = $class->collection()
		->update_many( $query, $update, $options );

	return $result->acknowledged() ?
		$result->modified_count() :
		undef;
}

sub delete {
	my ( $class, $query ) = @_;

	die( 'No collection defined!' )
		unless( defined( $class->collection() ) );

	my $result = $class->collection()
		->delete_many( $query );

	return $result->acknowledged() ?
		$result->deleted_count() :
		undef;
}

sub save {
	my $self = shift();
	my $class = blessed( $self );

	die( 'No collection defined!' )
		unless( defined( $class->collection() ) );

	my $document = $self->pack();
	$document->{_id} = delete( $document->{id} );

	unless( defined( $document->{_id} ) ) {
		my $result = $class->collection()
			->insert_one( $document );

		$self->id( $result->inserted_id() );
	} else {
		$class->collection()
			->replace_one( { _id => $self->id() }, $document, { upsert => 1 } );
	}

	return $self;
}

sub remove {
	my $self = shift();
	my $class = blessed( $self );

	die( 'No collection defined!' )
		unless( defined( $class->collection() ) );

	die( 'No identifier provided!' )
		unless( defined( $self->id() ) );

	$class->collection()
		->delete_one( { _id => $self->id() } );

	return $self;
}

sub drop {
	my $class = shift();

	die( 'No collection defined!' )
		unless( defined( $class->collection() ) );

	$class->collection()
		->drop();
}

sub to_object {
	my ( $class, $document ) = @_;

	$document->{id} = delete( $document->{_id} );

	return $class->unpack( $document );
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Mongol::Roles::Core - Core MongoDB actions and configuration

=head1 SYNOPSIS

	package Models::Person {
		use Moose;

		extends 'Mongol::Model';

		with 'Mongol::Roles::Core';

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

		has 'age' => (
			is => 'rw',
			isa => 'Int',
			default => 0,
		);

		__PACKAGE__->meta()->make_immutable();
	}

	...

	my $person = Models::Person->new(
		{
			first_name => 'Steve',
			last_name => 'Rogers',
		}
	);

	$person->save();
	printf( "User id: %s\n", $person->id()->to_string() )

	$person->age( 70 );
	$person->save();

=head1 DESCRIPTION

Mongol core functionality, this takes care of all the basic actions. This role should
be applied to master models.

=head1 ATTRIBUTES

=head2 collection

	my $collection = Models::Person->collection();

	my $collection = MongoDB->connect(...)
		->get_namespace( 'db.collection' );

	Models::Person->collection( $collection );

=head2 id

	my $id = $object->id();
	$object->id( $id );

=head1 METHODS

=head2 find

	my $cursor = Models::Person->find( $query, $options );

=head2 find_one

	my $object = Models::Person->find_one( $query, $options );

=head2 retrieve

	my $object = Models::Person->retrieve( $id );

Using the provided C<id> values searches for the document in the collection and
returns an instance of this model if found or C<undef> otherwise.

=head2 count

	my $count = Models::Person->count( $query, $options );

=head2 exists

	my $bool = Models::Person->exists( $id );

Checks weather the document with C<id> exists in the collection. Returns a boolean
value indicating if the document exists or not.

=head2 update

	my $count = Models::Person->update( $query, $update, $options );

=head2 delete

	my $count = Models::Person->delete( $query );

Removes documents that match the C<$query> form the associated collection.
Returns the number of the documents removed or C<undef>.

=head2 save

	$object->save();

Inserts or updates the instance model.

=head2 remove

	$object->remove();

Deletes the current object from the collection using the C<id> property.

=head2 drop

	Models::Person->drop();

Drops the MongoDB collection for this model.

=head2 to_object

	my $object = Models::Person->to_object( $hashref );

Creates a model instance from a hashref document.

=head1 SEE ALSO

=over 4

=item *

L<MongoDB::Collection>

=back

=cut
