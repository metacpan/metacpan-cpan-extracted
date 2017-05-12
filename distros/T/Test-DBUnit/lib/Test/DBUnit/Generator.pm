package Test::DBUnit::Generator;
use strict;
use warnings;
use Data::Dumper;
use Abstract::Meta::Class ':all';
use DBIx::Connection;
use Carp 'confess';
use XML::Writer;
use IO::File;

use vars qw($VERSION);

$VERSION = '0.22';


=head1 NAME

Test::DBUnit::Generator - dbunit dataset generator

=head1 SYNOPSIS

    use Test::DBUnit::Generator;

    my $connection = DBIx::Connection->new(
        name     => 'test',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    );

    my $generator = Test::DBUnit::Generator->new(
        connection      => $connection,
        datasets => {
            emp => 'SELECT * FROM emp',
            dept => 'SELECT * FROM demp',
        },
    );
    
    print $generator->xml_dataset;
    print $generator->dataset;


    pritn $generator->schema_validator(
        has_table        => 1,
        has_columns      => 1,
        has_pk           => 1,
        has_fk           => 1,
        has_index        => 1,
    );
    
    

=head1 DESCRIPTION

This class generates xml or perl test datasets based on passed in sql.
Additionally it can generate schema validator code.

=head2 ATTRIBUTES

=over

=item connection

=cut

has '$.connection';


=item datasets_order

Specifies order of the dataset in the generation result.

    my $generator = Test::DBUnit::Generator->new(
        connection      => $connection,
        datasets_order   => ['emp', 'dept'],
        datasets => {
            emp => 'SELECT * FROM emp',
            dept => 'SELECT * FROM demp',
        },
    );


=cut

has '@.datasets_order';


=item datasets

=cut

has '%.datasets' => (item_accessor => '_dataset');


=back

=head2 METHODS

=over

=item xml_dataset

Returns xml content that contains dataset 

=cut

sub xml_dataset {
    my ($self) = @_;
    my $output;
    my $file = IO::File->new;
    $file->open(\$output, '>');
    my $writer = new XML::Writer(OUTPUT => $file, NEWLINES => 1);
    $writer->xmlDecl("UTF-8");
    $writer->startTag("dataset", );
    my $datasets = $self->datasets;
    my @datasets_order = $self->_dataset_order;
    foreach my $k (@datasets_order) {
        my $data = $self->_select_dataset($k);
        for my $row (@$data) {
            $writer->emptyTag($k, %$row);
        }
    }
    $writer->endTag("dataset");
    $writer->end();
    $output =~ s/[\n\r](\s*\/>)/$1\n/g;
    $output =~ s/[\n\r](\s*>)/$1\n/g;
    $output;
}


*xml = \&xml_dataset;

=item dataset

Generated dataset as perl code

=cut

sub dataset {
    my ($self) = @_;
    local $Data::Dumper::Indent = 0;
    my $result = '';
    my $datasets = $self->datasets;
    my @datasets_order = $self->_dataset_order;
    
    foreach my $k (@datasets_order) {
        my $data = $self->_select_dataset($k);
        for my $row (@$data) {
            my $var = Dumper([%$row]);
            $var =~ s/\$VAR1/    $k/;
            $var =~ s/;$/,/;
            $var =~ s/=/=>/;
            $result .= ($result ? "\n" : ''). $var;
        }
    }
    return q{dataset_ok(
} . $result . q{
);}

}


*perl = \&dataset;


{
=item _inscrease_tests_no

=cut

my $test_no = 0;

    sub _inscrease_tests_no {$test_no++;}

=item schema_validator

Generates schema validation code.
Takes the following options as paramters:

has_table        => 1,
has_columns      => 1,
has_pk           => 1,
has_fk           => 1,
has_index        => 1,

=cut

    sub schema_validator {
        my ($self, %args) = @_;
        my $connection = $self->connection;
        my $tables = $connection->tables_info or return;
        my @tables = map { my $table = lc($_->{table_name}) } @$tables;
        my $output = '';
        my @keys =('has_table', 'has_columns', 'has_pk', 'has_fk', 'has_index');
        $test_no = 0;
        for my $table (@tables) {
            foreach my $key (@keys) {
                next unless $connection->has_table($table);
                next unless($args{$key});
                my $method = $self->can("_${key}");
                $output .= $method->($self, $table, \%args);
            }
        }
    
        return sprintf('use DBIx::Connection;
use Test::DBUnit connection_name => \'test\';
use Test::More tests => %s;

DBIx::Connection->new(
    name     => \'test\',
    dsn      => $ENV{DB_TEST_CONNECTION},
    username => $ENV{DB_TEST_USERNAME},
    password => $ENV{DB_TEST_PASSWORD},
);

%s', $test_no, $output);
    
    
}

}

=item _has_table

=cut

sub _has_table {
    my ($self, $table) = @_;
    _inscrease_tests_no();
    return sprintf("\nhas_table('%s');\n", $table);
}


=item _dataset_order

=cut

sub _dataset_order {
    my $self = shift;
    my $datasets = $self->datasets;
    my @datasets_order = $self->datasets_order;
    @datasets_order = keys %$datasets unless(@datasets_order);
    return @datasets_order;
}


=item _has_columns

=cut

sub _has_columns {
    my ($self, $table, $args) = @_;
    my $connection = $self->connection;
    my $columns = $connection->columns_info($table);
    my @columns = map { lc $_->{name} } @$columns;
    my $output = sprintf("has_columns('%s', [%s]);\n",
        $table, join(",", map { "'" . $_ . "'" } @columns)
    );
    _inscrease_tests_no();
    foreach my $k (@columns) {
        my $column_info = $connection->column_info($table, $k);
        $output .= sprintf("has_column('%s','%s');\n", $table, $k);
        _inscrease_tests_no();
        
        $output .= sprintf("column_type_is('%s','%s', '%s');\n", $table, $k, $column_info->{db_type});
        _inscrease_tests_no();
        
        if ($column_info->{nullable}) {
            $output .= sprintf("column_is_null('%s','%s');\n", $table, $k);
            _inscrease_tests_no();
        } else {
            $output .= sprintf("column_is_not_null('%s','%s');\n", $table, $k);
            _inscrease_tests_no();
        }
        
        if (my $default = $column_info->{default}) {
            $default =~ s/\'/\\\'/g;
            $output .= sprintf("column_default_is('%s', '%s', '%s');\n", $table, $k, $default);
            _inscrease_tests_no();
        }
        
        if ($column_info->{unique}) {
            $output .= sprintf("column_is_unique('%s', '%s');\n", $table, $k);
            _inscrease_tests_no();
        }
    }
    return $output;
}


=item _has_pk

=cut

sub _has_pk {
    my ($self, $table) = @_;
    my @primary_key_columns = $self->connection->primary_key_columns($table);
    my $output = '';
    if(@primary_key_columns) {
        $output = sprintf("has_pk('%s', [%s]);\n", $table, join(',', map { "'${_}'"} @primary_key_columns));
        _inscrease_tests_no();
    }
    return $output;
}


=item _has_fk

=cut

sub _has_fk {
    my ($self, $table) = @_;
    my $table_foreign_key_info = $self->connection->table_foreign_key_info($table);
    my $output = '';
    if($table_foreign_key_info) {
        for my $foreign_key_info (@$table_foreign_key_info) {
            my @columns = map {$_->[7]} @$foreign_key_info;
            my $info = $foreign_key_info->[0];
            $output .= sprintf("has_fk('%s', [%s], '%s');\n",
                $table,
                join(',', map { "'" . $_ . "'" } @columns),
                $info->[2]);
            _inscrease_tests_no();
        }
    }
    return $output;
}


=item _has_index

=cut

sub _has_index {
    my ($self, $table) = @_;
    my $table_indexes_info = $self->connection->table_indexes_info($table);
    my $output = '';
    if($table_indexes_info) {
        for my $index (@$table_indexes_info) {
            my $index_info = $index->[0];
            $output .= sprintf("has_index('%s', '%s', [%s]);\n",
                $table,
                $index_info->{index_name},
                join(",", map { "'" . $_->{column_name} . "'" } @$index)
            );
            _inscrease_tests_no();
            
            if ($index_info->{is_unique}) {
                $output .= sprintf("index_is_unique('%s','%s');\n", $table, $index_info->{index_name});
                _inscrease_tests_no();
            }

            if ($index_info->{is_pk}) {
                $output .= sprintf("index_is_primary('%s','%s');\n", $table, $index_info->{index_name});
                _inscrease_tests_no();
            }
        }
    }
    return $output;
}


=item _select_dataset

Returns dataset structure

=cut

sub _select_dataset {
    my ($self, $name) = @_;
    my $sql = $self->_dataset($name);
    my $cursor = $self->connection->query_cursor(sql => $sql);
    my $resultset = $cursor->execute();
    my $result = [];
    while($cursor->fetch()) {
        push @$result, {%$resultset};
    }
    $result;
}

=back

=cut

1;