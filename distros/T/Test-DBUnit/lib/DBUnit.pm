package DBUnit;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = '0.15';

use Abstract::Meta::Class ':all';
use base 'Exporter';
use Carp 'confess';
use DBIx::Connection;
use Simple::SAX::Serializer;

@EXPORT_OK = qw(INSERT_LOAD_STRATEGY REFRESH_LOAD_STRATEGY reset_schema populate_schema expected_dataset dataset expected_xml_dataset xml_dataset);
%EXPORT_TAGS = (all => \@EXPORT_OK);

use constant INSERT_LOAD_STRATEGY => 0;
use constant REFRESH_LOAD_STRATEGY => 1; 

=head1 NAME

DBUnit - Database testing API

=head1 SYNOPSIS

    use DBUnit ':all';

    my $dbunit = DBUnit->new(connection_name => 'test');
    $dbunit->reset_schema($script);
    $dbunit->populate_schema($script);

    $dbunit->dataset(
        emp   => [empno => 1, ename => 'scott', deptno => 10],
        emp   => [empno => 2, ename => 'john', deptno => 10],
        bonus => [ename => 'scott', job => 'consultant', sal => 30],
    );
    #business logic here

    my $differences = $dbunit->expected_dataset(
        emp   => [empno => 1, ename => 'scott', deptno => 10],
        emp   => [empno => 2, ename => 'John'],
        emp   => [empno => 2, ename => 'Peter'],
    );

    $dbunit->reset_sequence('emp_seq');

    $dbunit->xml_dataset('t/file.xml');

    $dbunit->expected_xml_dataset('t/file.xml');


B<LOBs support (Large Object)>

This code snippet will populate database blob_content column with the binary data pointed by file attribute,
size of the lob will be stored in size_column

    $dbunit->dataset(
        emp   => [empno => 1, ename => 'scott', deptno => 10],
        image  => [id => 1, name => 'Moon'
            blob_content => {file => 'data/image1.jpg', size_column => 'doc_size'}
        ]
    );


This code snippet will validate database binary data with expected content pointed by file attribute,

    $dbunit->expected_dataset(
        emp   => [empno => 1, ename => 'scott', deptno => 10],
        image => [id => 1, name => 'Moon'
            blob_content => {file => 'data/image1.jpg', size_column => 'doc_size'}
        ]
    );
    or xml
    <dataset>
        <emp .../>
        <image id=>"1" name="Moon">
            <blob_content  file="t/bin/data1.bin" size_column="doc_size" />
        </image>
    </dataset>


=head1 DESCRIPTION

Database test framework to verify that your database data match expected set of values.
It has ability to populate dataset and expected set from xml files.

=head2 EXPORT

None by default.
reset_schema
populate_schema
expected_dataset
expected_xml_dataset
dataset
xml_dataset by tag 'all'

=head2 ATTRIBUTES

=over

=item connection_name

=cut

has '$.connection_name' => (required => 1);


=item load_strategy

INSERT_LOAD_STRATEGY(default)
Deletes all data from tables that are present in test dataset in reverse order
unless empty table without attribute is stated, that force deletion in occurrence order
In this strategy expected dataset is also tested against number of rows for all used tables.

REFRESH_LOAD_STRATEGY
Merges (update/insert) data to the given dataset snapshot.
In this scenario only rows in expected dataset are tested.

=cut

has '$.load_strategy' => (default => INSERT_LOAD_STRATEGY());


=item primary_key_definition_cache

This option is stored as hash_ref:
the key is the table name with the schema prefix
and value is stored as array ref of primary key column names.


=cut

has '%.primary_key_definition_cache';


=back

=head2 METHODS

=over

=item reset_schema

Resets schema

    $dbunit->reset_schema;

=cut


sub reset_schema {
    my ($self, $file_name) = @_;
    my @tables_list = $self->objects_to_create(_load_file_content($file_name));
    my @to_drop;
    my @to_create;
    for (my $i = 0; $i <= $#tables_list; $i += 2) {
        push @to_drop, $tables_list[$i];
        push @to_create, $tables_list[$i + 1];
    }
    $self->drop_objects(reverse @to_drop);
    $self->create_tables(@to_create);
}


=item populate_schema

Populates database schema.

=cut

sub populate_schema {
    my ($self, $file_name) = @_;
    my @rows = $self->rows_to_insert(_load_file_content($file_name));
    my $connection = DBIx::Connection->connection($self->connection_name);
    for my $sql (@rows) {
        $connection->do($sql);
    }
    $connection->close();
}


=item dataset

Synchronizes/populates database to the passed in dataset.

    $dbunit->dataset(
        table1 => [], #this deletes all data from table1 (DELETE FROM table1)
        table2 => [], #this deletes all data from table2 (DELETE FROM table2)
        table1 => [col1 => 'va1', col2 => 'val2'], #this insert or update depend on strategy
        table1 => [col1 => 'xval1', col2 => 'xval2'],
    )

=cut

sub dataset {
    my ($self, @dataset) = @_;
    my $connection = DBIx::Connection->connection($self->connection_name);
    $self->delete_data(\@dataset, $connection);
    my $operation = ($self->load_strategy eq INSERT_LOAD_STRATEGY()) ? 'insert' : 'merge';
    for  (my $i = 0; $i < $#dataset; $i += 2) {
        my $table = $dataset[$i];
        my $lob_values = $self->_extract_lob_values($dataset[$i + 1]);
        my $data = $self->_extract_column_values($dataset[$i + 1]);
        next unless %$data;
        $self->$operation($table, $data, $connection);
        $self->_update_lobs($lob_values, $table, $data, $connection);
    }
    $connection->close();
}


=item expected_dataset

Validates database schema against passed in dataset.
Return differences report or undef is there are not discrepancies.

    my $differences = $dbunit->expected_dataset(
        table1 => [col1 => 'va1', col2 => 'val2'],
        table1 => [col1 => 'xval1', col2 => 'xval2'],
    );

=cut

sub expected_dataset {
    my ($self, @dataset) = @_;
    my $operation = ($self->load_strategy eq INSERT_LOAD_STRATEGY())
        ? 'expected_dataset_for_insert_load_strategy'
        : 'expected_dataset_for_refresh_load_strategy';
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $result = $self->$operation(\@dataset, $connection);
    $connection->close();
    $result;
}


=item reset_sequence

Resets passed in sequence

    $dbunit->reset_sequence('emp_seq');
    
=cut

sub reset_sequence {
    my ($self, $sequence_name) = @_;
    my $connection = DBIx::Connection->connection($self->connection_name);
    $connection->reset_sequence($sequence_name);
    $connection->close();
}


=item throws

Returns errorcode, error message for the specified sql or plsql code.

    my ($error_code, $error_message) = $dbunit->throws(
        "INSERT INTO emp(empno, ename) VALUES (NULL, 'Smith')"
    );

=cut


sub throws {
    my ($self, $pl_sql) = @_;
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $dbms = lc $connection->dbms_name;
    $pl_sql .= ';' unless ($pl_sql =~ /;$/);
    my ($error_code, $error_message);
    if ($dbms eq 'oracle' && !($pl_sql =~ /begin/i)) {
        $pl_sql = sprintf("BEGIN\n%sEND;", $pl_sql);
    } 
    my $dbh = $connection->dbh;
    my $sth = $connection->plsql_handler(plsql => $pl_sql);
    eval { $sth->execute(); };
    $error_code = $dbh->err;
    $error_message = $dbh->errstr;
    $connection->close();
    return ($error_code, $error_message);
}


=item execute

Returns hash reference where keys are the bind variables

    my $plsql = "SELECT NOW() INTO :var";
    my $result = $dbunit->execute($plsql);
    my $result = $dbunit->execute($plsql, $bind_variables_definition);

See L<DBIx::Connection> for more detail

=cut

sub execute {
    my ($self, $pl_sql, $bind_variables_definition) = @_;
    my $connection = DBIx::Connection->connection($self->connection_name);
    $pl_sql .= ';' unless ($pl_sql =~ /;$/);
    my $sth = $connection->plsql_handler(
        plsql          => sprintf("BEGIN\n%sEND;",$pl_sql),
        ($bind_variables_definition ? (bind_variables => $bind_variables_definition) :())
    );
    my $result = $sth->execute();
    $connection->close();
    $result;
}


=back

=head2 SCHEMA TEST METHODS

    The following methods check for existence.of the particular database
    schema objects like table, column, index, triggers,
    function, procedures packages.

=over

=item has_table

Returns true if the specified table exists.

    $dbunit->has_table($schema, $table);
    $dbunit->has_table($table);

=cut

sub has_table {
    my ($self, @args) = @_;
    my ($table, $schema) = (@args == 1) ? $args[0] : reverse @args;
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $result = $connection->has_table($table, $schema);
    $connection->close();
    return $result;
}


=item has_view

Returns true if the specified view exists.

    $dbunit->has_view($schema, $view);
    $dbunit->hasnt_table($view);

=cut

sub has_view {
    my ($self, @args) = @_;
    my ($view, $schema) = (@args == 1) ? $args[0] : reverse @args;
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $result = $connection->has_view($view, $schema);
    $connection->close();
    return $result;
}


=item has_column

Returns true if the specified column for given table exists.

    $dbunit->has_column($schema, $table, $columm);
    $dbunit->has_column($table, $columm);

=cut

sub has_column {
    my ($self, @args) = @_;
    my ($table, $column, $schema) = (@args == 2) ? @args : @args[1,2,0];
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $result = !! $connection->column($table, lc $column, $schema);
    $connection->close();
    return $result;
}


=item has_columns

Returns true if all specified columns exist for given table otherwise undef.
Check additionally failed_test_info method.

    my $columms = ['id', 'name']
    $dbunit->has_columns($schema, $table, $columms);
    $dbunit->has_column($table, $columms);

=cut

sub has_columns {
    my ($self, @args) = @_;
    my ($table, $columns, $schema) = (@args == 2) ? @args : @args[1,2,0];
    confess 'columns must be an array ref type'
        unless ref($columns) eq 'ARRAY';
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $db_columns = $connection->columns($table, $schema) || [];
    my @db_columns = map {lc($_->{name})} @$db_columns;
    $connection->close();
    
    my @missing = map { my $column = $_;
        (! (grep { lc($_) eq $column} @$columns) ? ($column) : ())
    } @db_columns;
    
    my @additional = map { my $column = lc($_);
        (! (grep { $_ eq $column} @db_columns) ? ($column) : ())
    } @$columns;
    
    my $result;
    $self->_set_failed_test_info('');
    if(@missing || @additional) {
        my $plural_missing = @missing > 1;
        $self->_set_failed_test_info(
            sprintf("got %s colunms: %s\nexpected: %s (-%s +%s)",
                $table,
                join (", ", @db_columns),
                join (", ", @$columns),
                join (", ", @missing),
                join (", ", @additional),
            )
        );
        $result = undef;
    } else {
        $result = 1;
    }
    return $result;
}


=item column_is_null

Returns true if the specified column for given table can be nullable.

    $dbunit->column_is_null($schema, $table, $columm);
    $dbunit->column_is_null($table, $columm);

=cut

sub column_is_null {
    my ($self, @args) = @_;
    my ($table, $column, $schema) = (@args == 2) ? @args : @args[1,2,0];
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $column_def = $connection->column($table, lc ($column), $schema);
    $connection->close();
    return undef unless $column_def;
    return exists ($column_def->{nullable}) ? $column_def->{nullable} : undef;
}


=item column_is_not_null

Returns true if the specified column for given table cant be nullable.

    $dbunit->column_is_not_null($schema, $table, $columm);
    $dbunit->column_is_not_null($table, $columm);

=cut

sub column_is_not_null {
    my ($self, @args) = @_;
    my ($table, $column, $schema) = (@args == 2) ? @args : @args[1,2,0];
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $column_def = $connection->column($table, lc ($column), $schema);
    $connection->close();
    return undef unless $column_def;    
    return exists ($column_def->{nullable}) ? ! $column_def->{nullable} : undef;
}


{
    my @data_type_aliases = (
        ['TEXT', 'VARCHAR', 'CHARACTER VARYING', 'VARCHAR2'],
        ['BPCHAR', 'CHAR', 'CHARACTER'],
        ['NUMERIC', 'FLOAT', 'DOUBLE PRECISION', 'DECIMAL'],
    );


=item _check_type_family

Checks data type families, tests if the specified testes type belongs to the same group as db_type (or dbi type)
There are currently the following synonyms for the families

    - 'TEXT', 'VARCHAR', 'CHARACTER VARYING', 'VARCHAR2'
    - 'BPCHAR', 'CHAR', 'CHARACTER'
    - 'NUMERIC', 'FLOAT'

=cut

sub _check_type_family {
    my ($self, $tested_type, $db_type) = @_;
    my $result;
    for my $type_family (@data_type_aliases) {
        if (scalar (grep {($tested_type =~ /$_/) || $db_type eq $_} @$type_family) > 1) {
                $result = $tested_type;
                last;
        }
    }
    unless($result) {
        $result = (lc($tested_type) eq lc $db_type) || ($tested_type =~ /\(/ && $tested_type =~ /$db_type/);
    }

    return $result ;
}

=item _data_type_aliases

=cut

sub _data_type_aliases {
    \@data_type_aliases;
}

=item _match_data_type

Returns undef if the specified data type matches underlying database type otherwise type name

=cut

    sub _match_data_type {
        my ($self, $tested_type, $dbi_type, $width, $db_type) = @_;
        my ($expected_width) = ($tested_type =~ /\(([^\)]+)/);
        my $result = $self->_check_type_family($tested_type, $dbi_type);
        if ($result && $expected_width) {
            $result = ($expected_width eq $width);
        }

        return $result ? undef : $db_type
            || ($dbi_type . (($dbi_type =~ /CHAR|NUM|FLOAT/ && $width > 0) ? "(${width})" : ''));
    }
}


=item column_type_is

Returns true if the specified column's type for given table matches 
underlying column type  otherwise undef;
Check additionally failed_test_info method.

    $dbunit->column_type_is($schema, $table, $columm, $type);
    $dbunit->column_type_is($table, $columm, $type);

=cut

sub column_type_is {
    my ($self, @args) = @_;
    my ($table, $column, $type, $schema) = (@args == 3) ? @args : @args[1,2,3,0];
    $self->_set_failed_test_info('');
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $column_def = $connection->column($table, lc ($column), $schema);
    $connection->close();
    unless ($column_def) {
        $self->_set_failed_test_info(sprintf("column %s doesn't exists in table %s", $column, $table));
        return undef;
    }
    my $type_ref = $column_def->{type_info} || {};
    my ($type_name, $width) = ($type_ref->{TYPE_NAME}, $column_def->{width});
    if($column_def->{db_type}) {
        ($type_name, $width) = ($column_def->{db_type} =~ /([^\(]+)\(([^\)]+)\)/);
        $type_name = $column_def->{db_type}
            unless $type_name;
    }
    if(my $result = $self->_match_data_type(uc($type), uc($type_name), $width, uc $column_def->{db_type})) {
        $self->_set_failed_test_info(sprintf("got %s type: %s\nexpected: %s", $column, $result, $type));
        return undef;
    }
    return !! $self;
}


=item column_default_is

Returns true if the specified column's default value matches database definition otherwise undef.
Check additionally failed_test_info.

    $dbunit->column_default_is($schema, $table, $columm, $default);
    $dbunit->column_default_is($table, $columm, $default);

=cut

sub column_default_is {
    my ($self, @args) = @_;
    my ($table, $column, $default, $schema) = (@args == 3) ? @args : @args[1,2,3,0];
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $column_def = $connection->column($table, lc ($column), $schema);
    $self->_set_failed_test_info('');
    $connection->close();
    unless ($column_def) {
        $self->_set_failed_test_info(sprintf("column %s doesn't exists in table %s", $column, $table));
        return undef;
    }
    my $quted_default = quotemeta($default);
    unless($column_def->{default} =~ /$quted_default/) {
        $self->_set_failed_test_info(sprintf("got default value: %s\nexpected: %s", $column_def->{default}, $default));
        return undef;
    }
    return !! $self;
}


=item column_is_unique

Returns true if the specified column for given table has unique constraint.

    $dbunit->column_is_unique($schema, $table, $column);
    $dbunit->column_is_unique($table, $column);

=cut

sub column_is_unique {
    my ($self, @args) = @_;
    my ($table, $column, $schema) = (@args == 2) ? @args : @args[1,2,0];
    $self->_set_failed_test_info('');
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $column_def = $connection->column($table, lc ($column), $schema);
    $connection->close();
    return undef unless $column_def;
    return $column_def->{unique};
}


=item has_pk

Returns true if the specified column or columns are part of the primary key
for the given table.

    my $columns = ['id']; #or my $columns = ['master_id', 'seq_no']; 

    $dbunit->has_pk($table, $columns);
    $dbunit->has_pk($schema, $table, $columns);


    $dbunit->has_pk($table, $column);
    $dbunit->has_pk($schema, $table, $column);

    $dbunit->has_pk($table);
    $dbunit->has_pk($schema, $table);

=cut

sub has_pk {
    my ($self, $schema, $table, $columns) = @_;
    my $connection = DBIx::Connection->connection($self->connection_name);
    my @primary_key_columns = $table && (! ref $table) ? $connection->primary_key_columns($table, $schema) : ();
    $self->_set_failed_test_info("");
    my $result;
    unless (@primary_key_columns) {
        $columns = $table;
        $table = $schema;
        $schema = undef;
        @primary_key_columns = $connection->primary_key_columns($table, $schema)
    }
    $connection->close;
    $result = !! @primary_key_columns;
    unless($result) {
        $self->_set_failed_test_info(sprintf("primary key doesn't exist on table %s", $table));
    }
    if ($result && $columns) {
        $columns = [$columns] unless ref($columns);
        for my $colunm (@$columns) {
            if(grep {$_ eq $colunm} @primary_key_columns) {
                $result = 1;
            } else {
                $result = undef;
                last;
            }
        }
        unless($result) {
            $self->_set_failed_test_info(sprintf("%s primary key columns don't match got: %s\nexpected: %s ",
                $table,
                join(", ",@$columns),
                join(", ", @primary_key_columns)
            ));
        }
    }
    return $result;
}



=item has_fk

Returns true if the specified column or columns for given table are part
of the foreign key for the referenced table.

    my $columns = ['id']; #or my $columns = ['master_id', 'seq_no']; 
    $dbunit->has_fk($schema, $table, $columns, $referenced_schema, $referenced_table);
    $dbunit->has_fk($table, $columns, $referenced_table);

=cut

sub has_fk {
    my ($self, @args) = @_;
    my ($table, $columns, $referenced_table, $schema, $referenced_schema) = (@args == 3)
        ? @args : @args[1, 2, 4, 0, 3];
    my $connection = DBIx::Connection->connection($self->connection_name);
    $self->_set_failed_test_info("");
    my $foreign_key_info = $connection->foreign_key_info($table, $referenced_table) || [];
    $connection->close;
    my %fk;
    for my $row (@$foreign_key_info) {
        my $id = $row->[11] || $row->[2];
        push @{$fk{$id}}, $row;
    }
    my $result = !! scalar %fk;
    for my $fk (values %fk) {
        my @foreign_key_columns = map {$_->[7]} @$fk;
        $columns = [$columns] unless ref($columns);
        for my $i (0 .. $#foreign_key_columns) {
            if(lc $columns->[$i] ne $foreign_key_columns[$i]) {
                $result = undef;
                last;
            } else {
                $result = 1;
            }
        }
        unless($result) {
            $self->_set_failed_test_info(sprintf("%s -> %s foreign key columns don't match got: %s\nexpected: %s ",
                    $table, $referenced_table,
                    join(", ",@$columns),
                    join(", ", @foreign_key_columns)
                ));
        }
        
        if ($result) {
            $self->_set_failed_test_info('');
            last;
        }
        
    }
    unless ($result) {
        $self->_set_failed_test_info(sprintf("foreign key doesn't exist for tables %s AND %s", $table, $referenced_table));
    }
    return $result;
}


=item has_index

Returns true if the specified column or columns are part of the index
for the given table.

    my $columns = ['id']; #or my $columns = ['master_id', 'seq_no']; 

    $dbunit->has_index($table, $index, $column_or_expressions);
    $dbunit->has_index($schema, $table, $index, $column_or_expressions);

    $dbunit->has_index($table, $index, $columns);
    $dbunit->has_index($schema, $table, $index, $columns);    
    
    $dbunit->has_index($table, $index);
    $dbunit->has_index($schema, $table, $index);

=cut

sub has_index {
    my ($self, $schema, $table, $index, @args) = @_;
    my $connection = DBIx::Connection->connection($self->connection_name);
    $self->_set_failed_test_info('');
    my $index_info = $connection->index_info($index, $schema, $table);
    my $columns;
    my $result;
    if(! $index_info || !@$index_info) {
        $columns = $index;
        $index = $table;
        $table = $schema;
        $schema = undef;
        $index_info = $connection->index_info($index, $schema, $table);
        $connection->close;
            return $result
                if (!$index_info || !@$index_info);
    }
    $connection->close;
    
    if(lc($index_info->[0]->{table_name}) ne lc($table)) {
        $self->_set_failed_test_info(sprintf("index %s doesn't match table got: %s\nexpected: %s",
            lc($index_info->[0]->{table_name}),
            lc($table)
        ));
    }
    $columns = ($index && @args ? shift @args : undef)
        unless $columns;
    if($columns) {
        $columns = [$columns] unless ref($columns);
        my @index_columns = map {$_->{column_name}} @$index_info;
        for my $i(0 .. $#index_columns) {
            if(lc $index_columns[$i] ne lc $columns->[$i]) {
                $result = undef;
                last;
            } else {
                $result = 1;
            }
        }
        
        $self->_set_failed_test_info(sprintf("index %s columns don't match got: %s\nexpected: %s",
            $index,
            join (', ', @index_columns),
            join (', ', @$columns)));
    } else {
        $result = 1;
    }
    return $result;
}


=item index_is_unique

Returns true if the specified index is unique.

    $dbunit->index_is_unique($schema, $table, $index);
    $dbunit->index_is_unique($table, $index);

=cut

sub index_is_unique {
    my ($self, @args) = @_;
    my ($table, $index, $schema) = (@args == 2) ? @args : @args[1,2,0];
    $self->_set_failed_test_info('');
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $index_info = $connection->index_info($index, $schema, $table);
    $connection->close;
    return undef if(! $index_info || !@$index_info);
    return !! $index_info->[0]->{is_unique};
}


=item index_is_primary

Returns true if the specified index is primary key.

    $dbunit->index_is_primary($schema, $table, $index);
    $dbunit->index_is_primary($table, $index);

=cut

sub index_is_primary {
    my ($self, @args) = @_;
    my ($table, $index, $schema) = (@args == 2) ? @args : @args[1,2,0];
    $self->_set_failed_test_info('');
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $index_info = $connection->index_info($index, $schema, $table);
    $connection->close;
    return undef if(! $index_info || !@$index_info);
    return !! ($index_info->[0]->{is_pk});
}


=item index_is_type

Returns true if the specified index's type is the index type
from underlying database, otherwise undef.
Check additionally failed_test_info method.

    $dbunit->index_is_type($schema, $table, $index, $type);
    $dbunit->index_is_type($table, $index, $type);

=cut

sub index_is_type {
    my ($self, @args) = @_;
    my ($table, $index, $type, $schema) = (@args == 3) ? @args : @args[1,2,3,0];
    $self->_set_failed_test_info('');
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $index_info = $connection->index_info($index, $schema, $table);
    $connection->close;
    $self->_set_failed_test_info('');
    if(! $index_info || !@$index_info) {
        $self->_set_failed_test_info("index ${index} doesn't exist");
    }
    
    if (lc($index_info->[0]->{index_type}) ne $type) {
        $self->_set_failed_test_info(sprintf("got index type: %s\nexpected: %s", $index_info->[0]->{index_type}, $type));
        return undef;
    }
    return $self;
}


=item has_trigger

Returns true if the specified trigger exists for the given table.

    $dbunit->has_trigger($schema, $table, $trigger);
    $dbunit->has_trigger($table, $trigger);

=cut

sub has_trigger {
    my ($self, @args) = @_;
    my ($table, $trigger, $schema) = (@args == 2) ? @args : @args[1,2,0];
    $self->_set_failed_test_info('');
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $trigger_info = $connection->trigger_info($trigger, $schema)
        or return undef;
    return undef
        if (lc($trigger_info->{table_name}) ne lc($table));
    return !! $trigger_info
}




=item has_sequence

Returns true if the specified sequence exists.

=cut

sub has_sequence {
    my ($self, @args) = @_;
    my ($sequence, $schema) = (@args == 1) ? $args[0] : reverse @args;
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $result = $connection->has_sequence($sequence, $schema);
    $connection->close();
    return $result;
}


=item trigger_is

Returns true if the specified trigger body matches the trigger body (or function in case of postgresql)
for given table, otherwise undef check additionally failed_test_info method.


    $dbunit->trigger_is($schema, $table, $trigger, $trigger_body);
    $dbunit->trigger_is($table, $trigger, $trigger_body);

=cut

sub trigger_is {
    my ($self, @args) = @_;
    my ($table, $trigger, $trigger_body, $schema) = (@args == 3) ? @args : @args[1,2,3,0];
    $self->_set_failed_test_info('');
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $trigger_info = $connection->trigger_info($trigger, $schema);
    $self->_set_failed_test_info('');
    unless ($trigger_info) {
        $self->_set_failed_test_info(sprintf("trigger %s doesn't exist", $trigger));
    }
    $connection->close;
    if (lc($trigger_info->{table_name}) ne lc($table)) {
        $self->_set_failed_test_info(sprintf("trigger %s doesn't exist for table %s, \ntrigger is defined on %s table",
            $trigger,
            ($trigger_info->{table_name} || ''),
            $table)
        );
        return undef;
    }
    
    my $trigger_func = $trigger_info->{trigger_func} || '';
    my $trigger_body_ =  $trigger_func . ' ' . $trigger_info->{trigger_body} ;
    unless($trigger_body_ =~ /$trigger_body/i) {
        $self->_set_failed_test_info(sprintf("got body: %s\nexpected: %s",$trigger_body, $trigger_body_));
        return undef;
    }
    return $self;
}


=item has_routine

Returns true if the specified routine exists and have matched prototype

    my $args = ['type1', 'type2', 'return_type'];
    or
    my $args = ['IN type1', 'OUT type2', 'type3'];
    or
    my $args = ['name1 type1', 'name2 type2', 'return type3'];
    or
    my $args = ['IN name1 type1', 'INOUT name2 type2', 'return type3'];
    
    $dbunit->has_routine($schema, $function);
    $dbunit->has_routine($function);
    $dbunit->has_routine($schema, $function, $args);
    $dbunit->has_routine($function, $args);

In case of testing function arguments, the last one is the function return type.
Check additionally failed_test_info method.

=cut

sub has_routine {
    my ($self, $schema, $function, $args) = @_;
    my $connection = DBIx::Connection->connection($self->connection_name);
    $self->_set_failed_test_info('');
    my $functions_info = $connection->routine_info($function, $schema);
    $self->_set_failed_test_info('');
    if (! $functions_info) {
        $args = $function;
        $function = $schema;
        $schema = undef;
        $functions_info = $connection->routine_info($function, $schema);
        unless  ($functions_info) {
            $self->_set_failed_test_info(sprintf("function %s doesn't exist", $function));
            return undef
        }
    }
    $connection->close;
    my $result = 1;
    if($args) {
        $args =[$args] unless ref($args) eq 'ARRAY';
        $result = undef;
        for my $routine_info (@$functions_info) {
            my $routine_args = $routine_info->{args};
            
            push @$routine_args, {type => $routine_info->{return_type}, name => 'return', mode => 'return'}
                if $routine_info->{return_type};

            for my $i (0 .. $#{$routine_args}) {
                my $res = $self->_validate_routine_argument($routine_args->[$i], $args->[$i], $routine_info);
                if($res) {
                    $result = 1;
                } else {
                    $result = undef;
                    last;
                }
            }
            last if $result;
        }

        unless($result) {
            $self->_set_failed_test_info(sprintf("function %s doesn't match the specified arguments %s\nexistsing prototypes: %s",
                $function,
                join (', ',@$args),
                join ("\n", map { $function .'(' . $_->{routine_arguments} .')'
                . ($_->{return_type} ? ' RETURNS ' . $_->{return_type} : '') } @$functions_info))
            );
        } else {
            $self->_set_failed_test_info('');
        }
    }
    return $result;
}


=item _validate_routine_argument

=cut

sub _validate_routine_argument {
    my ($self, $routine_arg, $arg, $routine_info) = @_;
    my $mode = ($arg =~ s/(IN OUT|IN|OUT|INOUT) //i) ? $1 : undef;
    
    if ($mode && lc($mode) ne lc $routine_arg->{mode}) {
        return undef;
    }
    
    my ($name, $type) = ($arg =~ /([^\s]+)\s+([^\s]+)/);
    $type = $arg unless $type;

    if ($name && lc($name) ne lc($routine_arg->{name})) {
        return undef;
    }

    if ($type && ! $self->_check_type_family(lc($type), lc($routine_arg->{type}))) {
        return undef;
    }
    return 1;
}



=item _set_failed_test_info

=cut

sub _set_failed_test_info {
    my ($self, $value) = @_;
    $self->{_failed_test_info} = $value;
}


=item failed_test_info

Stores the last failed test detail.

=cut

sub failed_test_info {
    shift()->{_failed_test_info} ||'';
}


=item routine_is

Returns true if the specified function matches passed in body


    $dbunit->has_routine($schema, $function, $args, $routine_body);
    $dbunit->has_routine($function, $args. $routine_body);

=cut

sub routine_is {
    my ($self, @args) = @_;
    my ($table, $function, $routine_body, $schema) = (@args == 2) ? @args : @args[1,2,3,0];
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $functions_info = $connection->routine_info($function, $schema);
    if (! $functions_info) {
        $routine_body = $function;
        $function = $schema;
        $schema = undef;
        $functions_info = $connection->routine_info($function, $schema)
            or return undef
    }
    my $result;
    foreach my $routine_info (@$functions_info) {
        if ($routine_info->{routine_body} =~ /$routine_body/) {
            $result = 1;
            last;
        }
    }
    return $result;
}



=item xml_dataset

Loads xml file to dataset and populates/synchronizes it to the database schema.
Takes xml file as parameter.

    <dataset load_strategy="INSERT_LOAD_STRATEGY" reset_sequences="emp_seq">
        <emp ename="scott" deptno="10" job="project manager" />
        <emp ename="john"  deptno="10" job="engineer" />
        <emp ename="mark"  deptno="10" job="sales assistant" />
        <bonus ename="scott" job="project manager" sal="20" />
    </dataset>

=cut

sub xml_dataset {
    my ($self, $file) = @_;
    my $xml = $self->load_xml($file);
    $self->apply_properties($xml->{properties});
    $self->dataset(@{$xml->{dataset}});
}


=item expected_xml_dataset

Takes xml file as parameter.
Return differences report or undef is there are not discrepancies.

=cut

sub expected_xml_dataset {
    my ($self, $file) = @_;
    my $xml = $self->load_xml($file);
    $self->apply_properties($xml->{properties});
    $self->expected_dataset(@{$xml->{dataset}});
}



=item apply_properties

Sets properties for this object.

=cut

sub apply_properties {
    my ($self, $properties) = @_;
    my $strategy = $properties->{load_strategy};
    $self->set_load_strategy(__PACKAGE__->$strategy);
    my $reset_sequences = $properties->{reset_sequences};
    if ($reset_sequences) {
        my @seqs = split /,/, $reset_sequences;
        for my $sequence_name (@seqs) {
            $self->reset_sequence($sequence_name);
        }
    }
}


=back

=head2 PRIVATE METHODS

=over

=item rows_to_insert

=cut

sub rows_to_insert {
    my ($self, $sql) = @_;
    map  {($_ =~ /\w+/ ?  $_ .')' : ())} split qr{\)\W*;}, $sql;
   
}


=item drop_objects

Removes existing schema

=cut

sub drop_objects {
    my ($self, @objects) = @_;
    my $connection = DBIx::Connection->connection($self->connection_name);
    my $dbms_name = lc($connection->dbms_name);
    my $cascade = ($dbms_name eq "postgresql" ? 'CASCADE' : '');
    for my $object (@objects) {
        next if ($object =~ /^\d+$/);
        if($object =~ m/table\s+`*(\w+)`*/i) {
            my $table = $1;
            $connection->do("DROP ${object} ${cascade}")
                if $connection->has_table($table);
        } elsif($object =~ m/view\s+`*(\w+)`*/i) {
            my $table = $1;
            $connection->do("DROP $object") 
                if $connection->has_view($table);
                
        } elsif($object =~ m/sequence\s+`*(\w+)`*/i) {
            my $sequence = $1;
            $connection->do("DROP ${object} ${cascade}")
                if $connection->has_sequence($sequence);
        } elsif(($object =~ m/(procedure)\s+`*(\w+)`*/i) || ($object =~ m/(function)\s+`*(\w+)`*/i)) {
            my ($type, $function) = ($1,$2);
            if (my $routines_info = $connection->routine_info($function)) {
                for my $routines_info(@$routines_info) {
                    next if(lc($type) eq  'procedure' && $routines_info->{return_type});
                    my $declation = '(' . $routines_info->{routine_arguments} . ')';
                    $connection->do("DROP $object "
                        . ((lc($connection->dbms_name) eq 'postgresql') ? $declation : ''));
                }
                
            }
        }
        
    }
    $connection->close();
}


=item create_tables

=cut

sub create_tables {
    my ($self, @tables) = @_;
    my $connection = DBIx::Connection->connection($self->connection_name);
    for my $sql (@tables) {
        $connection->do($sql);
    }
    $connection->close();
}



=item objects_to_create

Returns list of pairs values('object_type object_name', create_sql, ..., 'object_typeN object_nameN', create_sqlN)

=cut

sub objects_to_create {
    my ($self, $sql) = @_;
    my @result;
    my @create_sql = split /CREATE/i, $sql;
    
    my $i = 0;
    my $plsql_block = "";
    my $inside_plsql_block;

    for my $sql_statement (@create_sql) {
        next unless ($sql_statement =~ /\w+/);
        my ($object) = ($sql_statement =~ m/^\s+or\s+replace\s+(\w+\s+\w+)/i);
        unless($object) {
            ($object, my $name) = ($sql_statement =~ m/^\s+(\w+)\s+if\s+not\s+exists\s+(\w+)/i);
            $object .= " " . $name if $name;
        }
        unless($object) {
            ($object) = ($sql_statement =~ m/^\s+(\w+\s+\w+)/i);
        }
        $sql_statement =~ s/[;\n\r\s]+$//g;
        $sql_statement = "CREATE" . $sql_statement . ($object =~ /trigger|function|procedure/i ? ';': '');
        push @result, $object, $sql_statement;
    }
    @result;
}


=item insert

Inserts data

=cut

sub insert {
    my ($self, $table, $field_values, $connection) = @_;
    my @fields = keys %$field_values;
    my $sql = sprintf "INSERT INTO %s (%s) VALUES (%s)",
        $table, join(",", @fields), join(",", ("?")x @fields);
    $connection->execute_statement($sql, map {$field_values->{$_}} @fields);
}


=item merge

Merges passed in data

=cut

sub merge {
    my ($self, $table, $field_values, $connection) = @_;
    my %pk_values = $self->primary_key_values($table, $field_values, $connection);
    my $values = (%pk_values)  ? \%pk_values : $field_values;
    my $exists = $self->_exists_in_database($table, $values, $connection);
    if($exists) {
        my $pk_columns = $self->primary_key_definition_cache->{$table};
        return if(! $pk_columns || !(@$pk_columns));
    }
    my $operation  = $exists ? 'update' : 'insert'; 
    $self->$operation($table, $field_values, $connection);
}


=item update

Updates table values.

=cut

sub update {
    my ($self, $table, $field_values, $connection) = @_;
    my %pk_values = $self->primary_key_values($table, $field_values, $connection);
    my @fields = keys %$field_values;
    my @pk_fields = (sort keys %pk_values);
    my $where_clause = join(" AND ", map { $_ ." = ? " } @pk_fields);
    my $sql = sprintf "UPDATE %s SET %s WHERE %s",
        $table,
        join (", ", map { $_ . ' = ?' } @fields),
        $where_clause;
    $connection->execute_statement($sql, (map {$field_values->{$_}} @fields), (map { $pk_values{$_} } @pk_fields));
}


=item has_primary_key_values

Returns true if passed in dataset have primary key values

=cut

sub has_primary_key_values {
    my ($self, $table_name, $dataset, $connection) = @_;
    !! $self->primary_key_values($table_name, $dataset, $connection);
}


=item primary_key_values

Returns primary key values, Takes table name, hash ref as fields of values, db connection object.

=cut

sub primary_key_values {
    my ($self, $table_name, $dataset, $connection) = @_;
    my $pk_columns = $self->primary_key_definition_cache->{$table_name} ||= [$connection->primary_key_columns($table_name)];
    my @result;
    for my $column (@$pk_columns) {
        my $value = $dataset->{$column};
        return ()  unless defined $value;
        push @result, $column, $value;
    }
    @result;
}


=item delete_data

Deletes data from passed in tables.

=cut

sub delete_data {
    my ($self, $dataset, $connection) = @_;
    my @tables = $self->tables_to_delete($dataset);
    for my $table (@tables) {
        $connection->do("DELETE FROM $table");
    }
}


=item tables_to_delete

Returns list of tables to delete.

=cut

sub tables_to_delete {
    my ($self, $dataset) = @_;
    my @result = $self->empty_tables_to_delete($dataset);
    return @result if ($self->load_strategy ne INSERT_LOAD_STRATEGY());
    my %has_table = (map { $_ => 1 } @result);
    for  (my $i = $#{$dataset} - 1; $i >= 0; $i -= 2) {
        my $table = $dataset->[$i];
        next if $has_table{$table};
        $has_table{$table} = 1;
        push @result, $table;
    }
    @result;
}


=item empty_tables_to_delete

Returns list of table that are part of dataset table and are represented by table without attributes

  table1 => [],

  or in xml file

  <table1 />

=cut

sub empty_tables_to_delete {
     my ($self, $dataset) = @_;
     my @result;
     for  (my $i = 0; $i < $#{$dataset}; $i += 2) {
        next if @{$dataset->[$i + 1]};
        push @result, $dataset->[$i]
    }
    @result;
}


=item expected_dataset_for_insert_load_strategy

Validates expected dataset for the insert load strategy.

=cut

sub expected_dataset_for_insert_load_strategy {
    my ($self, $exp_dataset, $connection) = @_;
    my $tables = $self->_exp_table_with_column($exp_dataset, $connection);
    my %tables_rows = (map { ($_ => 0) } keys %$tables);
    my $tables_rows = $self->retrive_tables_data($connection, $tables);
    for (my $i = 0; $i < $#{$exp_dataset}; $i += 2) {
        my $table_name = $exp_dataset->[$i];
        my $fields = $exp_dataset->[$i + 1];
        if(ref($fields) eq 'HASH' && ! scalar(%$fields)) {
            if(my $rows = $self->count_table_rows($table_name, $connection)) {
               return  sprintf("table ${table_name} should not have rows, has %s row(s)", $rows);
            }
            next;
        }
        my %lob_values = $self->_extract_lob_values($fields);
        my %values = $self->_extract_column_values($fields);
        next if(! %values && !%lob_values);
        $tables_rows{$table_name}++;
        my $pk_columns = $self->primary_key_definition_cache->{$table_name} ||= [$connection->primary_key_columns($table_name)];
        my $result = $self->validate_dataset($tables_rows->{$table_name}, \%values, $pk_columns, $table_name, $connection, \%lob_values);
        return $result if $result;
    }
    $self->validate_number_of_rows(\%tables_rows, $connection);
}


=item _update_lobs

Updates lobs.

=cut

sub _update_lobs {
    my ($self, $lob_values, $table_name, $data, $connection) = @_;
    my $pk_columns = $self->primary_key_definition_cache->{$table_name} ||= [$connection->primary_key_columns($table_name)];
    my $fields_values = ($pk_columns && @$pk_columns) ? {map {($_ => $data->{$_})}  @$pk_columns} : $data;
    foreach my $lob_column (keys %$lob_values) {
        my $lob_attr = $lob_values->{$lob_column};
        my $lob_content = $lob_attr->{content};
        $connection->update_lob($table_name => $lob_column, $lob_content, $fields_values, $lob_attr->{size_column});
    }
}

=item _exp_table_with_column

Return hash ref of the tables with it columns.

=cut

sub _exp_table_with_column {
    my ($self, $dataset, $connection) = @_;
    my $result = {};
    for (my $i = 0; $i < $#{$dataset}; $i += 2) {
        my $columns = $result->{$dataset->[$i]} ||= {};
        my $data = $self->_extract_column_values($dataset->[$i + 1]);
        $columns->{$_} = 1 for keys %$data;
    }

    if ($connection) {
        foreach my $table_name (keys %$result) {
            my $pk_columns = $self->primary_key_definition_cache->{$table_name} ||= [$connection->primary_key_columns($table_name)];
            my $columns = $result->{$table_name} ||= {};
            $columns->{$_} = 1 for @$pk_columns;
        }
    }
    
    foreach my $k(keys %$result) {
        $result->{$k} = [sort keys %{$result->{$k}}];
    }
    $result;
}


=item _extract_column_values

=cut

sub _extract_column_values {
    my ($self, $dataset) = @_;
    my %values = @$dataset;
    my $result = {map {(!(ref($values{$_}) eq 'HASH') ? ($_ => $values{$_}) : ())} keys %values};
    wantarray ? (%$result) : $result;
}


=item _extract_column_values

=cut

sub _extract_lob_values {
    my ($self, $dataset) = @_;
    my %values = @$dataset;
    my $result = {map {(ref($values{$_}) eq 'HASH'  ? ($_ => $values{$_}) : ())} keys %values};
    $self->_process_lob($result);
    wantarray ? (%$result) : $result;
}


=item _process_lob

=cut

sub _process_lob {
    my ($self, $lobs) = @_;
    return if(! $lobs || !(keys %$lobs));
    for my $k(keys %$lobs) {
        my $lob_attr= $lobs->{$k};
        my $content = '';
        if($lob_attr->{file}) {
            $lob_attr->{content} = _load_file_content($lob_attr->{file});
        }
    }
}


=item validate_number_of_rows

Validates number of rows.

=cut

sub validate_number_of_rows {
    my ($self, $expected_result, $connection) = @_;
    foreach my $table_name (keys %$expected_result) {
        my $rows_no =$self->count_table_rows($table_name, $connection);
        return "found difference in number of the ${table_name} rows - has "  . $rows_no . " rows, should have " . $expected_result->{$table_name}
            if (! defined $rows_no ||  $expected_result->{$table_name} ne $rows_no);
    }
}


=item validate_dataset

Validates passed exp dataset against fetched rows.
Return undef if there are not difference otherwise returns validation error.

=cut

sub validate_dataset {
    my ($self, $rows, $exp_dataset, $pk_columns, $table_name, $connection, $lob_values) = @_;
    my $hash_key = primary_key_hash_value($pk_columns, $exp_dataset);

    if ($lob_values && %$lob_values) {
        my $result = $self->validate_lobs($lob_values, $table_name, $pk_columns, $exp_dataset, $connection);
        return $result if $result;
    }

    my @columns = keys %$exp_dataset;
    if ($hash_key) {
        my $result = compare_datasets($rows->{$hash_key}, $exp_dataset, $table_name, @columns);
        if ($rows->{$hash_key}) {
            return $result if $result;
            delete $rows->{$hash_key};
            return;
        }
    } else {#validation without primary key values
        my $exp_hash = join("-", map { $_ || '' } values %$exp_dataset);
        foreach my $k (keys %$rows) {
            my $dataset = $rows->{$k};
            my $rowhash = join("-", map {($dataset->{$_} || '')} @columns);
            if ($rowhash eq $exp_hash) {
                delete $rows->{$k};
                return;
            }
        }
    }
    "found difference in $table_name - missing row: "
    . "\n  ". format_values($exp_dataset, @columns);
}


=item validate_lobs

Validates lob values

=cut

sub validate_lobs {
    my ($self, $lob_values, $table_name, $pk_column, $exp_dataset, $connection) = @_;
    return if(! $lob_values || ! (%$lob_values));
    my $fields_value = ($pk_column && @$pk_column)
        ? {map {($_ => $exp_dataset->{$_})} @$pk_column}
        : $exp_dataset;
    for my $lob_column(keys %$lob_values) {
        my $lob_attr = $lob_values->{$lob_column};
        my $exp_lob_content = $lob_attr->{content};
        my $lob_content = $connection->fetch_lob($table_name => $lob_column, $fields_value, $lob_attr->{size_column});
        return "found difference at LOB value ${table_name}.${lob_column}: " . format_values($fields_value, keys %$fields_value)
            if(length($exp_lob_content || '') ne length($lob_content || '') || ($exp_lob_content || '') ne ($lob_content || ''));
    }
}


=item expected_dataset_for_refresh_load_strategy

Validates expected dataset for the refresh load strategy.

=cut

sub expected_dataset_for_refresh_load_strategy {
    my ($self, $exp_dataset, $connection) = @_;
    for (my $i = 0; $i < $#{$exp_dataset}; $i += 2) {
        my $table_name = $exp_dataset->[$i];
        my $fields = $exp_dataset->[$i + 1];
        if (ref($fields) eq 'HASH' && ! scalar(%$fields)) {
            if(my $rows = $self->count_table_rows($table_name, $connection)) {
               return  sprintf("table ${table_name} should not have rows, has %s row(s)", $rows);
            }
            next;
        }
        my %values = $self->_extract_column_values($fields);
        my %lob_values = $self->_extract_lob_values($fields);
        my $pk_columns = $self->primary_key_definition_cache->{$table_name} ||= [$connection->primary_key_columns($table_name)];
        my $result = $self->validate_expexted_dataset(\%values, $pk_columns, $table_name, $connection, \%lob_values);
        return $result if $result;
    }
}


=item count_table_rows

Return number of the table rows,
    
    my $no_rows = $dbunit->has_empty_table($table, $connection);

=cut

sub count_table_rows {
    my ($self, $table_name, $connection) = @_;
    my $result = $connection->record("SELECT COUNT(*) AS cnt FROM ${table_name}");
    return $result->{cnt};
}


=item validate_expexted_dataset

Validates passed exp dataset against database schema
Return undef if there is not difference otherwise returns validation error.

=cut

sub validate_expexted_dataset {
    my ($self, $exp_dataset, $pk_columns, $table_name, $connection, $lob_values) = @_;
    my @condition_columns = (@$pk_columns ? @$pk_columns : map { (!ref($exp_dataset->{$_}) ? ($_) : ()) }  keys %$exp_dataset);
    if ($lob_values && %$lob_values) {
        my $result = $self->validate_lobs($lob_values, $table_name, \@condition_columns, $exp_dataset, $connection);
        return $result if $result;
    }
        
    my $where_clause = join(" AND ", map { $_ ." = ? " } @condition_columns);
    my @columns = keys %$exp_dataset;
    my $record = $connection->record("SELECT " . (join(",", @columns) || '*') . " FROM ${table_name} WHERE ". $where_clause, map    { $exp_dataset->{$_} } @condition_columns);
    if(grep { defined $_ } values %$record) {
        return compare_datasets($record, $exp_dataset, $table_name, keys %$exp_dataset);
    }
    "found difference in $table_name - missing row: "
    . "\n  ". format_values($exp_dataset, keys %$exp_dataset);
}


=item compare_datasets

Compares two dataset hashes using passed in keys
Returns undef if there is not difference, otherwise difference details.

=cut

sub compare_datasets {
    my ($dataset, $exp_dataset, $table_name, @keys) = @_;
    for my $k (@keys) {
        if (ref $exp_dataset->{$k}) {
            my $result = $exp_dataset->{$k}->($dataset->{$k});
             return "found difference in $table_name $k:"
                . "\n  " . format_values($dataset, @keys)
                unless $result;
             next;
        }
        return "found difference in $table_name $k:"
        . "\n  " . format_values($exp_dataset, @keys)
        . "\n  " . format_values($dataset, @keys)
        if (($dataset->{$k} || '') ne ($exp_dataset->{$k} || ''));
    }
}


=item format_values

Converts passed in list to string.

=cut

sub format_values {
    my ($dataset, @keys) = @_;
    "[ " . join(" ",  map { $_ . " => '" . (defined $dataset->{$_} ? $dataset->{$_} : '')  . "'" } @keys) ." ]";
}


=item retrive_tables_data

Returns retrieved data for passed in tables

=cut

sub retrive_tables_data {
    my ($self, $connection, $tables) = @_;
    my $result = {};
    for my $table_name (keys %$tables) {
        $result->{$table_name} = $self->retrive_table_data($connection, $table_name, $tables->{$table_name});
    }
    $result;
}


=item retrive_table_data

Returns retrieved data for passed in table.

=cut

sub retrive_table_data {
    my ($self, $connection, $table_name, $columns) = @_;
    my $counter = 0;
    my $pk_columns = $self->primary_key_definition_cache->{$table_name} ||= [$connection->primary_key_columns($table_name)];
    my $cursor = $connection->query_cursor(sql => "SELECT " . (join(",", @$columns) || '*') . " FROM ${table_name}");
    my $result_set = $cursor->execute();
    my $has_pk = !! @$pk_columns;
    my $result = {};
    while ($cursor->fetch()) {
        my $key = $has_pk ? primary_key_hash_value($pk_columns, $result_set) : "__" . ($counter++);
        $result->{$key} = {%$result_set};
    }
    $result;
}


=item primary_key_hash_value

Returns primary key values hash.

=cut

sub primary_key_hash_value {
    my ($primary_key_columns, $field_values) = @_;
    my $result = "";
    for (@$primary_key_columns) {
        return undef unless defined($field_values->{$_});
        $result .= $field_values->{$_} . "#";
    }
    $result;
}



=item xml_dataset_handler

=cut

{   my $xml;

    sub xml_dataset_handler {
        unless($xml) {
            $xml = Simple::SAX::Serializer->new;
            $xml->handler('dataset', sub {
                    my ($self, $element, $parent) = @_;
                    $element->validate_attributes([],
                        {load_strategy => "INSERT_LOAD_STRATEGY", reset_sequences => undef}
                    );
                    my $attributes = $element->attributes;
                    my $children_result = $element->children_result;
                    {properties => $attributes, dataset => $children_result}
                }
            );
            $xml->handler('*', sub {
                my ($self, $element, $parent) = @_;
                my $parent_name = $parent->name;
                my $attributes = $element->attributes;
                if($parent_name eq 'dataset') {
                    my $children_result = $element->children_result || {};
                    my $parent_result = $parent->children_array_result;
                    my $result = $parent->children_result;
                    push @$parent_result, $element->name => [%$children_result, map { $_ => $attributes->{$_}} sort keys %$attributes];
                } else {
                    # hacky
                    my $children_result = $parent->children_hash_result;
                    my $value = $element->value(1);
                    unless(scalar %$attributes) {
                        $children_result->{$element->name} = eval "sub { $value }";
                   } else {
                        $element->validate_attributes([], {size_column => undef, file => undef});
                        my $children_result = $parent->children_hash_result;
                        $children_result->{$element->name} = {%$attributes};
                        $children_result->{content} = $value if $value;
                   }
                }
            });
        }
        $xml;
    }
}


=item _exists_in_database

Check is rows exists in database.
Takes table name, hash ref of field values, connection object

=cut

sub _exists_in_database {
    my ($self, $table_name, $field_values, $connection) = @_;
    my $sql = "SELECT 1 AS cnt FROM ${table_name} WHERE ".join(" AND ", map {($_ . " = ? ")} sort keys %$field_values);
    my $record = $connection->record($sql,  map {$field_values->{$_}} sort keys %$field_values);
    $record && $record->{cnt};
}


=item load_xml

Loads xml

=cut

sub load_xml {
    my ($self, $file) = @_;
    my $xml = $self->xml_dataset_handler;
    $xml->parse_file($file);
}


=item _load_file_content

=cut

sub _load_file_content {
    my $file_name = shift;
    open my $fh, '<', $file_name or confess "cant open file ${file_name}";
    binmode $fh;
    local $/ = undef;
    my $content = <$fh>;
    close $fh;
    $content;
}

1;

__END__

=back

=head1 TODO

Extend detection for complex plsql blocks in the objects_to_create method.

=head1 COPYRIGHT AND LICENSE

The DBUnit module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.



=head1 SEE ALSO

L<DBIx::Connection>

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut