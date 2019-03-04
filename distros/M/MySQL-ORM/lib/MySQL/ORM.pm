package MySQL::ORM;

use 5.006;
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use SQL::Abstract::Complete;
use MySQL::Util::Lite;

our $VERSION = '0.06';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use MySQL::ORM;

    my $foo = MySQL::ORM->new();
    ...

=cut

##############################################################################
## public attributes
##############################################################################

has dbh => (
	is       => 'rw',
	isa      => 'Object',
	required => 1,
	trigger  => sub {
		my $self = shift;
		$self->dbh->{FetchHashKeyName} = 'NAME_lc';
	}
);

has schema_name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_schema_name'
);


##############################################################################
## protected attributes
##############################################################################

has __lite => (
	is      => 'rw',
	isa     => 'MySQL::Util::Lite',
	lazy    => 1,
	builder => '_build__lite'
);

##############################################################################
## private attributes
##############################################################################

has _schema => (
	is      => 'rw',
	isa     => 'MySQL::Util::Lite::Schema',
	lazy    => 1,
	builder => '_build_schema',
);

has _sql => (
	is      => 'rw',
	default => sub { return SQL::Abstract::Complete->new; }
);

has _prune_ddl => (
	is      => 'ro',
	isa     => 'HashRef',
	default => sub {
		return {
			distinct  => 1,
			left_join => 1,
			order_by  => 1,
		};
	}
);

##############################################################################
# public methods
##############################################################################


=head1 SUBROUTINES/METHODS

=head2 function1

=cut

#sub function1 {
#}

method select (
    Str       :$table!,
    ArrayRef  :$columns = ['*'],
    HashRef   :$where = {},
    ArrayRef  :$order_by,
    HashRef   :$other = {},
    Bool      :$distinct = 0,
    Bool      :$for_update = 0,
    ) {

	if ($order_by) {
		$other->{order_by} = $order_by;
	}
	
	my $fq_table = $self->_fq_table($table);

	my ( $stmt, @bind ) =
	  $self->_sql->select( $fq_table, $columns, $where, $other );
	$stmt .= " for update" if $for_update;
	$stmt =~ s/^select/select distinct/ if $distinct;

	my $sth = $self->dbh->prepare($stmt);
	$sth->execute(@bind);

	my $cnt = 0;
	my @rows;

	while ( my $href = $sth->fetchrow_hashref ) {
		push @rows, {%$href};
	}

	return \@rows;
}

method select_one (
    Str      :$table!,
    ArrayRef :$columns = ['*'],
    HashRef  :$where = {},
    HashRef  :$other = {},
    Bool     :$confess_on_no_rows = 0,
    Bool     :$for_update = 0
    ) {

	$other->{limit} = 1;

	my $aref = $self->MySQL::ORM::select(
		table      => $table,
		columns => $columns,
		where      => $where,
		other      => $other,
		for_update => $for_update,
	);

	if ( !defined $aref->[0] ) {

		if ($confess_on_no_rows) {

			my $msg =
			  sprintf( "failed to find row from table $table where =>\n%s\n%s",
				Dumper($where), Dumper($other) );
			confess $msg;
		}

		return;
	}

	return $aref->[0];
}

method delete (Str     :$table!,
               HashRef :$where) {

    my $fq_table = $self->_fq_table($table);
    
	my ( $stmt, @bind ) = $self->_sql->delete( $fq_table, $where );
	my $rows = $self->dbh->do( $stmt, undef, @bind );

	return $rows;
}

method update (
    Str     :$table!,
    HashRef :$values!,
    HashRef :$where = {}
    ) {

    my $fq_table = $self->_fq_table($table);
    
	my ( $stmt, @bind ) = $self->_sql->update( $fq_table, $values, $where );

	return $self->dbh->do( $stmt, undef, @bind );
}

method upsert (Str     :$table!,
               HashRef :$values!) {

	my $into_cols = join( ', ', keys(%$values) );

    my $fq_table = $self->_fq_table($table);
    
	my @bind;
	my @on_dup_bind;
	my @on_dup_clause;
	my @values_qmarks;

	foreach my $key ( keys %$values ) {
		push @values_qmarks, '?';
		push @bind,          $values->{$key};
		push @on_dup_clause, "$key = values($key)";
		push @on_dup_bind,   $values->{$key};
	}

	my $values_qmarks = join( ', ', @values_qmarks );
	my $on_dup_clause = join( ', ', @on_dup_clause );

	my $sql = qq{
        insert into 
            $fq_table 
            ($into_cols)
        values
            ($values_qmarks)
        on duplicate key 
        update
            $on_dup_clause
    };
	my $rows = $self->dbh->do( $sql, undef, @bind );

	# rows = 1 is an insert
	# rows = 2 is an update
	if ( $rows != 1 and $rows != 2 ) {
		my $msg =
		  sprintf "got unexpected row count ($rows) for:\ntable = $table\n%s",
		  pdump $values;
		confess $msg;
	}

	if ( $self->dbh->{mysql_insertid} ) {
		my $id = $self->dbh->{mysql_insertid};
		return $id;
	}
	else {

		my $autoinc_col = $self->MySQL::ORM::_get_autoinc_col($table);
		
		if ( defined $autoinc_col ) {
			my $href = $self->MySQL::ORM::select_one( table => $table, where => $values );
			return $href->{$autoinc_col};
		}
		else {
			return;    # no id to return
		}
	}

	confess "should not get here...";
}

method insert (Str     :$table, 
               HashRef :$values,
               Bool	   :$ignore = 0) {

    my $fq_table = $self->_fq_table($table);
    
	my ( $stmt, @bind ) = $self->_sql->insert( $fq_table, $values );

	if ($ignore) {
		$stmt =~ s/^insert /insert ignore /i;
	}

	my $rows = $self->dbh->do( $stmt, undef, @bind );

	if ( !$ignore ) {
		confess "should have received 1, but got $rows"
		  if $rows != 1;

		if ($self->MySQL::ORM::_is_pk_autoinc($table) ) {
			my $id = $self->dbh->{mysql_insertid};
			return $id;
		}

		# return row count
		return $rows;
	}
}

method make_where_clause (HashRef :$where!) {

	my @bind;
	my $where_sql = '';

	if ( keys %$where > 0 ) {
		my $where_clause;
		( $where_sql, @bind ) = $self->_sql->where($where);
	}

	return ( $where_sql, @bind );
}

method prune_ddl_args (ArrayRef $args) {

	my %args = @$args;

	my %pruned;
	my $ddl = $self->_prune_ddl;

	foreach my $key ( keys %args ) {
		if ( !$ddl->{$key} ) {
			$pruned{$key} = $args{$key};
		}
	}

	return %pruned;
}

###############################################################################
# private methods
##############################################################################

method _fq_table(Str $table){
    return $self->schema_name . "." . $table;
}

method _is_pk_autoinc (Str $table) {

	my $t  = $self->_schema->get_table($table);
	my $pk = $t->get_primary_key;

	return $pk->is_autoinc;
}

method _get_autoinc_col (Str $table) {

	my $t   = $self->_schema->get_table($table);
	my $col = $t->get_autoinc_column;

	if ($col) {
		return $col->name;
	}

	return;
}

method _build_schema {

	return $self->__lite->get_schema;
}

method _build_schema_name {
    my $dbh = $self->dbh;
	my $schema = $dbh->selectrow_arrayref("select schema()")->[0];
	
	return $schema;
}

method _build__lite {
	
	my $schema = $self->schema_name;
	my $clone = $self->dbh->clone;
	$clone->do("use $schema");
	
	return MySQL::Util::Lite->new( dbh => $clone, span => 1 );
}

1;

=head1 AUTHOR

John Gravatt, C<< <gravattj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mysql-orm at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MySQL-ORM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MySQL::ORM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MySQL-ORM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MySQL-ORM>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/MySQL-ORM>

=item * Search CPAN

L<https://metacpan.org/release/MySQL-ORM>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 John Gravatt.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of MySQL::ORM
