package MySQL::Insert;

use warnings;
use strict;

our $MAX_ROWS_TO_QUERY = 1000;

=head1 NAME

MySQL::Insert - extended inserts for MySQL via DBI

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    # Insert two rows into sample_table using $dbh database handle

    use MySQL::Insert;

    $MySQL::Insert::MAX_ROWS_TO_QUERY = 1000;

    my $inserter = MySQL::Insert->new( $dbh, 'sample_table', [ @field_names ], %param );

    # Param can be:
    # statement = 'INSERT' | 'REPLACE' | 'INSERT IGNORE' (by default)
    # on_duplicate_update = { field_name => field_value, .. } (not used by default)

    # simple insertion
    $inserter->insert_row( { fldname => 'fldvalue1' } );
    $inserter->insert_row( { fldname => 'fldvalue2' } );

    # multirow insertion
    $inserter->insert_row( { fldname => 'fldvalue3' }, { fldname => 'fldvalue4' } );
    $inserter->insert_row( [ 'fldvalue5' ], [ 'fldvalue6' ] } );

    # Insert row into sample_table using $dbh database handle
    # If fldvalue3 is passed as scalar ref then it is not quoted
    # Used to insert MySQL built-in functions like NOW() and NULL values.
    # @field_names must be predefined in case of arrayref row data usage

    $inserter->insert_row( { fldname => \'NOW()' } );

    undef $inserter;

=head1 DESCRIPTION

Use multiple-row INSERT syntax that include several VALUES lists.
(for example INSERT INTO test VALUES ('1',Some data',2234),('2','Some More Data',23444)).
EXTENDED INSERT syntax is more efficient of execution many insert queries.
It is not compatible with most RDBMSes.

=head1 FUNCTIONS / METHODS

The following methods are available:

=head2 new

Create new MySQL::Insert object

=cut

sub new {
    my $type = shift;

    my $self = { };
    $self = bless $self, $type;
    $self->_init( @_ );
    return $self;
}

sub _init {
    my ( $self, $dbh, $table, $fields, %ext_params ) = @_;

    $self->{_dbh} = $dbh;
    $self->{_table} = $table;

    $self->set_fields( $fields );

    $self->{_total_rows} = 0;
    $self->{_do_append_row_to_query} = 0;
    $self->{_query_exists} = 0;
    $self->{_statement} = $ext_params{statement} || 'INSERT IGNORE';
    $self->{_on_duplicate_update} = $ext_params{on_duplicate_update};
}

=head2 set_fields

Set fields list (by plain list or list reference)

=cut

sub set_fields {
    my $self = shift;

    return unless @_ && $_[0];

    my @fields = ref $_[0] ? @{$_[0]} : @_;

    $self->{_fields} = \@fields;
    $self->{_name_fields} = "( " . ( join ", ", map "`$_`", @fields ) . " )";

    return 1;
}

=head2 get_fields

Get fields list (or its quantity in scalar context)

=cut

sub get_fields {
    my ($self) = @_;

    return unless $self->{_fields};
    return wantarray ? @{$self->{_fields}} : scalar @{$self->{_fields}};
}

DESTROY {
    my $self = shift;

    $self->_finish_current_row;

    $self->_execute_query();
}

=head2 insert_row

Schedule row for insertion

=cut

sub insert_row {
    my ( $self, @new_rows ) = @_;

    my $query_executed = 0;

    foreach my $new_row ( @new_rows ) {
	$query_executed = 1 if $self->_finish_current_row();

	$self->{_do_append_row_to_query} = 1;
	$self->{_current_row} = $new_row;
   }

    return $query_executed;
}

# Private methods

sub _finish_current_row {
    my $self = shift;

    my $query_executed;

    if ( $self->{_do_append_row_to_query} ) {

	if ( $self->{_total_rows} >= $MAX_ROWS_TO_QUERY ) {
	    $query_executed = $self->_execute_query();
	}

	$self->_append_row_to_query_rows;

	$self->{_do_append_row_to_query} = 0;
    }

    return $query_executed;
}

sub _execute_query {
    my $self = shift;

    return if ! $self->{_query_exists};

    my $values = join ',', @{$self->{_query_rows}};

    my $query = "$self->{_statement} $self->{_table} $self->{_name_fields} VALUES $values";

    if ( $self->{_statement} =~ /^INSERT/i && $self->{_on_duplicate_update} ) {

	my $update_statement = join ', ',
	    map { "$_ = " . $self->_prepare_value( $self->{_on_duplicate_update}->{$_} ) }
		keys %{ $self->{_on_duplicate_update} };

	$query .= ' ON DUPLICATE KEY UPDATE ' . $update_statement;
    }

    my $result = $self->{_dbh}->do( $query ) or return;

    # clear everyting
    $self->{_query_exists} = 0;
    $self->{_total_rows} = 0;
    $self->{_query_rows} = [];

    return $result;
}

sub _append_row_to_query_rows {
    my ( $self ) = @_;

    unless ( $self->get_fields() ) {
	die 'Undefined field names!' unless ref $self->{_current_row} eq 'HASH';

	$self->set_fields( keys %{$self->{_current_row}} );
    }

    my @data_row;

    if ( ref $self->{_current_row} eq 'HASH' ) {
	for my $field ( $self->get_fields() ) {
	    push @data_row, $self->_prepare_value( $self->{_current_row}->{ $field } );
	}
    }
    else {
	push @data_row, map { $self->_prepare_value( $_ ) } @{ $self->{_current_row} };
    }

    push @{$self->{_query_rows}}, "\n\t( ".join(', ', @data_row)." )";

    $self->{_query_exists} = 1;
    $self->{_total_rows}++;
}

sub _prepare_value {
    my ( $self, $value ) = @_;

    if ( ref $value eq 'SCALAR' ) {
	return ${ $value } || q{''};
    }
    else {
	return $self->{_dbh}->quote( $value );
    }
}


=head1 AUTHORS

Gleb Tumanov C<< <gleb at reg.ru> >> (original author)
Walery Studennikov C<< <despair at cpan.org> >> (CPAN distribution)

=head1 BUGS

Please report any bugs or feature requests to C<bug-mysql-insert at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MySQL-Insert>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MySQL::Insert
