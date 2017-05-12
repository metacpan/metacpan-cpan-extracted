package Role::Pg::Sequences;
$Role::Pg::Sequences::VERSION = '0.002';
use 5.010;
use Moose::Role;
use DBI;

has 'sequences_dbh' => (
	is => 'ro',
	isa => 'DBI::db',
	lazy_build => 1,
);

sub _build_sequences_dbh {
	my $self = shift;
	return $self->dbh if $self->can('dbh');
	return $self->schema->storage->dbh if $self->can('schema');
}

has 'sequences_schema' => (
	is => 'rw',
	isa => 'Str',
	predicate => '_has_sequences_schema',
);

sub create_sequence {
	my ($self, %args) = @_;
	my $dbh = $self->sequences_dbh;
	my $sequence = $dbh->quote_identifier($args{sequence}) or return;
	my $temp = $dbh->quote_identifier($args{temporary}) ? 'TEMP' : '';
	if (!$temp and $self->_has_sequences_schema) {
		my $schema = $dbh->quote_identifier($self->sequences_schema);
		$sequence = "$schema.$sequence";
	}
	my @params = grep {exists $args{$_} and $args{$_} =~ /^\d+$/} qw/ increment minvalue maxvalue start cache /;
	my $params = join ' ', map {"$_ $args{$_}"} @params;

	my $sql = qq{
		CREATE $temp SEQUENCE $sequence $params
	};
	$self->sequences_dbh->do($sql);
}

sub drop_sequence {
	my ($self, %args) = @_;
	my $dbh = $self->sequences_dbh;
	my $sequence = $dbh->quote_identifier($args{sequence}) or return;
	if ($self->_has_sequences_schema) {
		my $schema = $dbh->quote_identifier($self->sequences_schema);
		$sequence = "$schema.$sequence";
	}

	my $sql = qq{
		DROP SEQUENCE $sequence
	};
	$self->sequences_dbh->do($sql);
}

sub sequence_exists {
	my ($self, %args) = @_;
	my $dbh = $self->sequences_dbh;
	my $schema = $self->sequences_schema;
	my $sequence = $args{sequence} or return;
	if ($self->_has_sequences_schema) {
		my $schema = $self->sequences_schema;
		$sequence = "$schema.$sequence";
	}
	my @values = ($sequence);

	my $sql = qq{
		SELECT * FROM pg_class
			WHERE relkind = 'S'
			AND oid::regclass::text = ?
	};
	my $sequence_value = $self->sequences_dbh->selectrow_arrayref($sql, undef, @values);
	return $sequence_value->[0] ? 1 : 0;
}

sub nextval {
	my ($self, %args) = @_;
	my $dbh = $self->sequences_dbh;
	my $schema = $self->sequences_schema;
	my $sequence = $args{sequence} or return;
	if ($self->_has_sequences_schema) {
		my $schema = $self->sequences_schema;
		$sequence = "$schema.$sequence";
	}
	my @values = ($sequence);

	my $sql = qq{
		SELECT nextval(?)
	};
	my $sequence_value = $self->sequences_dbh->selectrow_arrayref($sql, undef, @values) || return;
	return $sequence_value->[0];
}

sub setval {
	my ($self, %args) = @_;
	my $dbh = $self->sequences_dbh;
	my $schema = $self->sequences_schema;
	my $sequence = $args{sequence} or return;
	if ($self->_has_sequences_schema) {
		my $schema = $self->sequences_schema;
		$sequence = "$schema.$sequence";
	}
	my $value = $args{value} || 1;
	my @values = ($sequence, $value);
	my $no_params = 2;
	if (defined(my $is_called = $args{is_called})) {
		$no_params++;
		push @values, $is_called;
	}
	my $qs = join(',',('?') x $no_params);
	my $sql = qq{
		SELECT setval($qs)
	};
	my $sequence_value = $self->sequences_dbh->selectrow_arrayref($sql, undef, @values) || return;
	return $sequence_value->[0];
}

sub lastval {
	my ($self, %args) = @_;
	my $dbh = $self->sequences_dbh;
	my $sql = qq{
		SELECT lastval()
	};
	my $sequence_value = $self->sequences_dbh->selectrow_arrayref($sql) || return;
	return $sequence_value->[0];
}

1;

=pod

=encoding UTF-8

=head1 NAME

Role::Pg::Sequences - Client Role for handling PostgreSQL Sequences

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This role handles the use of Sequences in a PostgreSQL database.

=head1 NAME

Role::Pg::Sequences

=head1 ATTRIBUTES

=head2 sequences_dbh

Role::Pg::Sequences tries to guess your dbh. If it isn't a standard dbi::db named dbh, or
constructed in a dbix::class schema called schema, you have to return the dbh from
_build_sequences_dbh.

=head2 sequences_schema

Should be set to the name of the database schema to hold the sequence. Default "public".

=head1 METHODS

=head2 create_sequence

 $self->create_sequence(sequence => 'my_sequence');

 Optional parameters:

 	temporary - if set, means that the sequence is temporary and will disappear when the current session is closed
	increment - the value that the sequence will be incremented by
	minvalue - the minimumn value of the sequence. Default 1
	maxvalue - the maximum value of the sequence. Default 2^63-1
	start - Which value to be the first. Default minvalue
	cache - How many sequence numbers to cache

Creates a sequence.

An optional password can be added. The user (or group) is then created with an encrypted password.

=head2 drop_sequence

 $self->drop_sequence(sequence => 'my_sequence');

Drops a sequence.

=head2 sequence_exists

 print "It's there" if $self->sequence_exists(sequence => 'my_sequence');

Returns true if the sequence exists.

=head2 nextval

 my $sequence_value = $self->nextval(sequence => 'my_sequence');

Increments and returns the next value of the sequence

=head2 setval

 $self->nextval(sequence => 'my_sequence', value => $new_value);

 Returns the new value

 The optional parameter is_called determines if the value is already incremented. Set this parameter to a false value
 if you want the next nextval to NOT increment the value.

Sets the value of the sequence

=head2 lastval

 my $sequence_value = $self-lastval;

Returns the latest value of any sequence

=head1 AUTHOR

Kaare Rasmussen <kaare@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2015, Kaare Rasmussen

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Client Role for handling PostgreSQL Sequences

