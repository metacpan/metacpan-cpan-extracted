package Norma::ORM::Table;
our $VERSION = "0.02";

use Moose;

has 'name' => (is => 'ro', required => 1);
has 'db'   => (is => 'ro', required => 1);

has 'primary_key_field_names' => (is => 'rw');
has 'key_field_names'         => (is => 'rw');
has 'mutable_field_names'     => (is => 'rw');
has 'columns'                 => (is => 'rw');

sub BUILD {

	my ($self, $args) = @_;

	my $table_name = $self->name;

	$self->_set_table_definition;
	$self->_set_table_primary_key_field_names;
	$self->_set_table_key_field_names;

	for my $column (@{ $self->{columns} }) {

		$column->{_NORMA_PRIMARY_KEY} = grep { $_ eq $column->{COLUMN_NAME} } @{ $self->primary_key_field_names } ? 1 : 0;

		$column->{_NORMA_REQUIRED} = 
			$column->{NULLABLE} == 0 
			&& ! defined $column->{COLUMN_DEF}
			&& ! $column->{mysql_is_auto_increment};
	}
}

sub select {
	my ($self, %args) = @_;
	$self->db->select(
		%args,
		table_name => $self->name,
	);
}

sub _set_table_definition {
	my ($self) = @_;

	my $columns = $self->db->get_table_definition(
		table_name => $self->name,
	);

	$self->columns($columns);
}

sub _set_table_primary_key_field_names {
	my ($self) = @_;

	my $primary_key_field_names = $self->db->get_table_primary_key_field_names(
		table_name => $self->name,
	);

	$self->primary_key_field_names($primary_key_field_names);
}

sub _set_table_key_field_names {
	my ($self) = @_;

	my $key_field_names = $self->db->get_table_key_field_names(
		table_name => $self->name,
	);

	$self->key_field_names($key_field_names);
	
}

sub primary_key {
	my ($self) = @_;
	return $self->primary_key_field_names->[0];
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Norma::ORM::Table - Representation of a database table for use by other L<Norma> classes

=head1 AUTHOR

David Chester <davidchester@gmx.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2011 by David Chester.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

