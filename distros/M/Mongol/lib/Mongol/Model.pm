package Mongol::Model;

use Moose;

use MooseX::Storage;
use MooseX::Storage::Engine;

with Storage( base => 'SerializedClass' );

my @MAPPED_CLASSES = qw(
	MongoDB::OID
	MongoDB::DBRef
	MongoDB::BSON::Binary
	DateTime
);

MooseX::Storage::Engine->add_custom_type_handler(
	$_ => (
		expand => sub { shift() },
		collapse => sub { shift() },
	)
) foreach ( @MAPPED_CLASSES );

around 'pack' => sub {
	my $orig = shift();
	my $self = shift();

	my %args = @_;

	my $result = $self->$orig( %args );
	delete( $result->{__CLASS__} )
		if( $args{no_class} );

	return $result;
};

sub serialize {
	my $self = shift();

	return $self->pack( no_class => 1 );
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Mongol::Model - Everything is a model

=head1 SYNOPSIS

	package Models::Person {
		use Moose;

		extends 'Mongol::Model';

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
		use strict;
		use warnings;

		use Model::Person;

		my $person => Model::Person->new(
			{
				first_name => 'Peter',
				last_name => 'Parker',
			}
		);

		my $hashref = $person->pack();
		my $clone = Model::Person->unpack( $hashref );

		my $nice_hashref = $person->serialize();
	}

=head1 DESCRIPTION

In Mongol there's no need to defined your model classes as document or subdocument
it knows automatically to diferentiate between them. Everything should be a model,
if you're planning to store that information in the database then make sure your
class inherits from this package. Right now all it does it takes care of the data
serialization for you and it makes sure that some of the datatypes are converted correctly.

=head1 METHODS

=head2 pack

	my $hashref = $model->pack();

Inherited from L<MooseX::Storage>.

=head2 unpack

	my $model = Model::Class->unpack( $hashref );

Inherited from L<MooseX::Storage>.

=head2 serialize

	my $hashref = $model->serialize();

Just like B<pack> except it drops the B<__CLASS__> field from the resulting
hash reference.

=head1 SEE ALSO

=over 4

=item *

L<MooseX::Storage>

=back

=cut
