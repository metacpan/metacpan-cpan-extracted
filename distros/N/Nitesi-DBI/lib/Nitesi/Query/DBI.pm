package Nitesi::Query::DBI;

use strict;
use warnings;

=head1 NAME

Nitesi::Query::DBI - DBI query engine for Nitesi

=head1 SYNOPSIS

    $query = Nitesi::Query::DBI->new(dbh => $dbh);

    $query->select(table => 'products',
                   fields => [qw/sku name price/],
                   where => {price < 5},
                   order => 'name',
                   limit => 10);

    $query->insert('products', {sku => '9780977920150', name => 'Modern Perl'});

    $query->update('products', {media_format => 'CD'}, {media_format => 'CDROM'});

    $query->delete('products', {inactive => 1});

=head1 DESCRIPTION

This query engine is based on L<SQL::Abstract> and L<SQL::Abstract::More> and
supports the following query types:

=over 4

=item select

Retrieving data from one or multiple tables.

=item insert

Inserting data in one table.

=item update

Updating data in one table.

=item delete

Deleting data from one table.

=back

=head2 SELECT QUERIES

=head3 Distinct example

    @skus = $query->select_list_field(table => 'navigation_products',
                   field => 'sku',
                   distinct => 1,
                   where => {navigation => 1});

=head3 Order and limit example

    $products = $query->select(table => 'products', 
                   fields => [qw/sku title price description media_type/],
		   where => {inactive => 0}, 
                   order => 'entered DESC', 
                   limit => 10);

=head3 Join example

    $roles = $query->select(join => [qw/user_roles rid=rid roles/],
                            fields => [qw/roles.rid roles.name/],
		            where => {uid => 1});

=head1 ATTRIBUTES

=head2 dbh

DBI database handle.

=head2 sqla

L<SQL::Abstract::More> object.

=head2 log_queries

Code reference use to log queries.

=cut

use Moo;

use SQL::Abstract;
use SQL::Abstract::More;

has dbh => (
    is => 'ro',
);

has sqla => (
    is => 'rw',
    lazy => 1,
    default => sub {SQL::Abstract::More->new()},
);

has log_queries => (
    is => 'rw',
);


=head1 METHODS

=head2 select

Runs query and returns records as hash references inside a array reference.

    $results = $query->select(table => 'products',
                              fields => [qw/sku name price/],
                              where => {price < 5});

    print "Our cheap offers: \n\n";

    for (@$results) {
        print "$_->{name} (SKU: $_->{sku}), only $_->{price}\n";
    }


B<Example:> List first 10 - sku, name and price from table products where price is lower than 5, order them by name.

    $query->select(table => 'products',
                   fields => [qw/sku name price/],
                   where => {price < 5},
                   order => 'name',
                   limit => 10);

B<Example:> Join user_roles and roles by rid and show rid and name from roles table.

    $query->select(join => 'user_roles rid=rid roles',
			where => { uid => 1 },
			fields => [qw/roles.rid roles.name],
		);

B<Example:> Where clause can be used as defined in L<SQL::Abstract> and L<SQL::Abstract::More>. In this example we find all roles whose name begins with "adm". -ilike is standard DB ILIKE ( minus sign is a sign for database operator and it's not related to negation of the query ).

    $query->select(join => 'user_roles rid=rid roles',
			where => { roles.name => {-ilike => 'adm%' },
			fields => [qw/roles.rid roles.name],
		);

B<Example:> Where clause can be used as defined in L<SQL::Abstract> and L<SQL::Abstract::More>. In this example we find all roles whose name is either "admin" or "super".

    $query->select(join => 'user_roles rid=rid roles',
			where => { roles.name => {-in => ['admin', 'super' },
			fields => [qw/roles.rid roles.name],
		);


=cut

sub select {
    my ($self, %args) = @_;
    my ($stmt, @bind, @fields, %extended, @sql_params);

    if (exists $args{fields}) {
	@fields= ref($args{fields}) eq 'ARRAY' ? @{$args{fields}} : split /\s+/, $args{fields};
    }
    else {
	@fields = ('*');
    }
    
    if ($args{distinct}) {
	@fields = ('-distinct' => @fields);
    }

    if ($args{join}) {
	my @join = ref($args{join}) eq 'ARRAY' ? @{$args{join}} : split /\s+/, $args{join};

	$extended{-from} = [-join => @join];
    }

    if ($args{limit}) {
	$extended{-limit} = $args{limit};
    }

    if ($args{offset}) {
        $extended{-offset} = $args{offset};
    }

    if (keys %extended || $fields[0] =~ /^-/) {
	# extended syntax for a join / limit / distinct
	$extended{-from} ||= $args{table};

	if ($args{order}) {
	    $extended{-order_by} = $args{order};
	}

	unless (exists $args{where}) {
	    # SQL::Abstract::More chokes on undefined where
	    $args{where} = {};
	}

	@sql_params = (-columns => \@fields,
		       -where => $args{where},
		       %extended,
	    );
    }
    else {
	@sql_params = ($args{table}, \@fields, $args{where}, $args{order});
    }

    eval {
	($stmt, @bind) = $self->sqla->select(@sql_params);
    };

    if ($@) {
	die "Failed to parse select parameters (", join(',', @sql_params) , ": $@\n";
    }

    return $self->_run($stmt, \@bind, %args);
}

=head2 select_field

Runs query and returns value for the first field (or undef).


B<Example:> Get name of product 9780977920150.

	$name = $query->select_field(table => 'products', 
                                 field => 'name', 
                                 where => {sku => '9780977920150'});

=cut

sub select_field {
    my ($self, %args) = @_;

    if ($args{field}) {
	$args{fields} = [delete $args{field}];
    }

    $args{return_value} = 'value_first';

    return $self->select(%args);
}

=head2 select_list_field

Runs query and returns a list of the first field for all matching records, e.g.:

B<Example:> Get all sku's from products where media_type is 'DVD'.

	@dvd_skus = $query->select_list_field(table => 'products',
                                    field => 'sku',
                                    where => {media_type => 'DVD'});

=cut

sub select_list_field {
    my ($self, %args) = @_;

    if ($args{field}) {
	$args{fields} = [delete $args{field}];
    }

    $args{return_value} = 'array_first';

    return $self->select(%args);
}

=head2 insert

Runs insert query

B<Example:>

    $query->insert('products', {sku => '9780977920150', name => 'Modern Perl'});

=cut

sub insert {
    my ($self, @args) = @_;
    my ($stmt, @bind, $ret, @keys);

    ($stmt, @bind) = $self->sqla->insert(@args);

    $ret = $self->_run($stmt, \@bind, return_value => 'execute');

    # determine primary keys
    @keys = $self->{dbh}->primary_key(undef, undef, $args[0]);
    
    if (@keys == 1) {
        if (exists $args[1]->{$keys[0]} && defined $args[1]->{$keys[0]}) {
            return $args[1]->{$keys[0]};
        }
        elsif ($self->{dbh}->{Driver}->{Name} eq 'mysql') {
            return $self->{dbh}->last_insert_id(undef, undef, $args[0], undef);
        }
        elsif ($self->{dbh}->{Driver}->{Name} eq 'Pg') {
            my ($seq_stmt, $seq_name, $seq_val, $sth);
            
            # determine whether primary key uses an sequence
            $seq_stmt = q{select pg_get_serial_sequence(?, ?)};

            if ($seq_name = $self->_run($seq_stmt, [$args[0], $keys[0]], return_value => 'value_first')) {
                $seq_val = $self->_run('select currval(?)', [$seq_name], return_value => 'value_first');
                return $seq_val;
            }
        }
    }

    return $ret;
}

=head2 update

Runs update query, either with positional or name parameters.
Returns the number of matched/updated records.

B<Example:> Positional parameters

    $updates = $query->update('products', {media_format => 'CD'}, {media_format => 'CDROM'});

B<Example:> Named parameters - similar to using SQL to update the table.

    $updates = $query->update(table => 'products', 
                              set => {media_format => 'CD'}, 
                              where => {media_format => 'CDROM'});

=cut

sub update {
    my $self = shift;
    my ($stmt, @bind);

    if (@_ == 2 || @_ == 3) {
	# positional parameters (table, updates, where)
	($stmt, @bind) = $self->sqla->update(@_);
    }
    else {
	# named parameters
	my %args = @_;

	($stmt, @bind) = $self->sqla->update($args{table}, $args{set}, $args{where});
    }

    $self->_run($stmt, \@bind, return_value => 'execute');
}

=head2 delete

Runs delete query, either with positional or named parameters.

B<Example:> Positional parameters

    $query->delete('products', {inactive => 1});

B<Example:> Named parameters - similar to using SQL to delete the record.

    $query->delete(table => 'products', where => {inactive => 1});

=cut

sub delete {
    my $self = shift;
    my ($stmt, @bind);

    if (@_ == 1 || @_ == 2) {
	# positional parameters (table, where)
	($stmt, @bind) = $self->sqla->delete(@_);
    }
    else {
	# named parameters
	my %args = @_;
	($stmt, @bind) = $self->sqla->delete($args{table}, $args{where});
    }

    $self->_run($stmt, \@bind, return_value => 'execute');
}

sub _run {
    my ($self, $stmt, $bind_ref, %args) = @_;
    my ($sth, $row, @result, $ret);

    if ($self->log_queries) {
        $self->log_queries->($stmt, $bind_ref, \%args);
    }

    unless ($sth = $self->{dbh}->prepare($stmt)) {
	die "Failed to prepare $stmt: $DBI::errstr\n";
    }

    unless ($ret = $sth->execute(@$bind_ref)) {
	die "Failed to execute $stmt: $DBI::errstr\n";
    }

    if ($args{return_value}) {
	if ($args{return_value} eq 'execute') {
	    return $ret;
	}
	if ($args{return_value} eq 'array_first') {
	    return map {$_->[0]} @{$sth->fetchall_arrayref()};
	}
	if ($args{return_value} eq 'value_first') {
	    if ($row = $sth->fetch()) {
		return $row->[0];
	    }
	    return;
	}
	
	die "Invalid return_value for SQL query.";
    }

    while ($row = $sth->fetchrow_hashref()) {
	push @result, $row;
    }

    return \@result;
}

# private methods for testing, likely to promoted to public methods in the future
sub _tables {
    my ($self) = @_;
    my (@tables);

    @tables = $self->dbh->tables;

    if ($self->dbh->{Driver}->{Name} eq 'mysql') {
	@tables = map {s/^`(.*)`\.`(.*)`$/$2/; $_} @tables;
    }

    return @tables;
}

sub _create_table {
    my ($self, $table, $fields) = @_;
    my ($stmt, @bind);

    $stmt = $self->sqla->generate('create table', \$table, $fields);

    $self->_run($stmt, [], return_value => 'execute');
}

sub _drop_table {
    my ($self, $table, $fields) = @_;
    my ($stmt, @bind);

    $stmt = $self->sqla->generate('drop table', \$table);

    $self->_run($stmt, [], return_value => 'execute');
}

=head2 dbh

Returns DBI database handle.

=head2 sqla

Returns embedded SQL::Abstract::More object.

=head1 CAVEATS

Please anticipate API changes in this early state of development.

We don't recommend to use Nitesi::Query::DBI with file backed DBI
drivers like L<DBD::DBM>, L<DBD::CSV>, L<DBD::AnyData> or L<DBD::Excel>.
In case you want to do this, please install L<SQL::Statement> first,
as the statements produced by this module are not understood by
L<DBI::SQL::Nano>.

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
