package Mongol::Cursor;

use Moose;

has 'result' => (
	is => 'ro',
	isa => 'MongoDB::QueryResult',
	required => 1,
);

has 'type' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

sub all {
	my $self = shift();

	return map { $self->type()->to_object( $_ ) }
		$self->result()->all();
}

sub has_next {
	my $self = shift();

	return $self->_result()
		->has_next()
}

sub next {
	my $self = shift();

	my $document = $self->result()
		->next();

	return defined( $document ) ?
		$self->type()->to_object( $document ) : undef;
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Mongol::Cursor - Mongol cursor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 type

	my $type = $cursor->type()

The class type associated for this cursor. All documents retrieved with this cursor
will be automatically deserialized using this class definition.

=head2 result

	my $result = $cursor->result();

The original L<MongoDB::QueryResult> on which this cursor wraps.

=head1 METHODS

=head2 all

	my @objects = $cursor->all();

Returns all the cursor result as an array of objects.

=head2 has_next

	my $bool = $cursor->has_next();

Checks if there are any objects in the cursor.

=head2 next

	my $object = $cursor->next();

Returns the next object in the cursor.

=head1 SEE ALSO

=over 4

=item *

L<MongoDB::Cursor>

=item *

L<MongoDB::QueryResult>

=back

=cut
