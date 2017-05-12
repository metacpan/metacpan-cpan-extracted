
package SQL::Admin::Driver::Base::Decompose;

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################
######################################################################
sub new {                                # ;
    my ($class, %param) = @_;

    bless \ %param, ref $class || $class;
}


######################################################################
######################################################################
sub decompose {                          # ;
    my ($self, $catalog) = @_;
    my (@retval, %map);

    local $self->{log} = {};

    my $sorter = sub { $a->fullname cmp $b->fullname };

    ##################################################################

    for my $entity (qw( schema sequence table index column primary_key unique foreign_key )) {
        my $log = $self->{log}{$entity} ||= {};
        my $method = 'create_' . $entity;

        for my $obj (sort $sorter values %{ $catalog->list ($entity) }) {
            next if exists $log->{$obj->fullname};
            push @retval, $self->$method ($catalog, $obj);
        }
    }

    ##################################################################

    for my $obj (sort $sorter values %{ $catalog->list ('table') }) {
        push @retval, $self->table_row ($obj);
    }

    ##################################################################

    \ @retval;
}

######################################################################
######################################################################
sub create_schema {                      # ;
    my ($self, $catalog, $schema) = @_;

    $self->{log}{schema}{ $schema->fullname } = 1;

    +{ create_schema => {
        schema_identifier => $schema->name,
    }};
}


######################################################################
######################################################################
sub create_table {                       # ;
    my ($self, $catalog, $table) = @_;

    $self->{log}{table}{ $table->fullname } = 1;

    +{ create_table => {
        table_name => { name => $table->name, schema => $table->schema },
        table_content => [
            ( map $self->create_table_column ($catalog, $table->column ($_)), $table->columns ),
        ],
    }};
}


######################################################################
######################################################################
sub create_table_column {                # ;
    my ($self, $catalog, $column) = @_;
    my $type = { %{ $column->type } };
    $type->{data_type} = delete $type->{type};

    my @param = (
        table => $column->table,
        column_list => [ $column->name ],
    );

    my $primary_key = $catalog->exists (primary_key => @param);
    my $unique      = $catalog->exists (unique => @param);

    $self->{log}{column}{ $column->fullname } = 1;
    $self->{log}{primary_key}{ $primary_key } = 1;
    $self->{log}{unique}{ $unique } = 1;

    ##################################################################

    +{ column_definition => {
        column_name => $column->name,
        %$type,
        ($primary_key ? (column_primary_key => 1) : ()),
        ($unique ? (column_unique => 1) : ()),
        (map +(column_not_null => 1), grep $_, $column->not_null),
        (map +(default_clause => $_), grep $_, $column->default),
        ($column->autoincrement ? (autoincrement => $column->autoincrement_hint) : ()),
    }};
}


######################################################################
######################################################################
sub create_index {                       # ;
    my ($self, $catalog, $index) = @_;

    +{ create_index => {
        index_name => { name => $index->name, schema => $index->schema },
        table_name => { name => $index->table->name, schema => $index->table->schema },
        ($index->unique ? (index_unique => 1) : ()),
        index_column_list => [
            map +{
                column_name => $_->[0],
                ($_->[1] ? (column_order => $_->[1]) : ()),
            }, @{ $index->column_list }
        ]
    }};
}


######################################################################
######################################################################
sub create_primary_key {                 # ;
    my ($self, $catalog, $obj) = @_;

    +{ alter_table => {
        table_name => { name => $obj->table->name, schema => $obj->table->schema },
        alter_table_actions => [ {
            add_constraint => { primary_key_constraint => {
                column_list => $obj->column_list,
            }}
        }]
    }};
}


######################################################################
######################################################################
sub create_unique {                      # ;
    my ($self, $catalog, $obj) = @_;

    +{ alter_table => {
        table_name => { name => $obj->table->name, schema => $obj->table->schema },
        alter_table_actions => [ {
            add_constraint => { unique_constraint => {
                (map {(constraint_name => $_)} grep $_, $obj->name),
                column_list => $obj->column_list,
            }}
        }]
    }};
}


######################################################################
######################################################################
sub create_foreign_key {                 # ;
    my ($self, $catalog, $obj) = @_;

    +{ alter_table => {
        table_name => { name => $obj->table->name, schema => $obj->table->schema },
        alter_table_actions => [ {
            add_constraint => { foreign_key_constraint => {
                (map +(constraint_name => $_), grep $_, $obj->name),
                referencing_column_list => $obj->referencing_column_list,
                referenced_column_list  => $obj->referenced_column_list,
                referenced_table => {
                    name => $obj->referenced_table->name,
                    schema => $obj->referenced_table->schema,
                },
                (map +(update_rule => $_), grep $_, $obj->update_rule),
                (map +(delete_rule => $_), grep $_, $obj->delete_rule),
            }}
        }]
    }};
}


######################################################################
######################################################################
sub drop_schema {                        # ;
    my ($self, $catalog, $schema) = @_;

    +{ drop_schema => {
        schema_identifier => $schema->name,
    }};
}


######################################################################
######################################################################
sub add_column {                         # ;
    my ($self, $catalog, $column) = @_;

    my $data_type = { %{ $column->type } };
    $data_type->{data_type} = delete $data_type->{type};

    # print Data::Dumper::Dumper ($column->default);
    +{ alter_table => {
        table_name => { name => $column->table->name, schema => $column->table->schema },
        alter_table_actions => [ { add_column => [ { column_definition => {
            column_name    => $column->name,
            %$data_type,
            not_null       => $column->not_null,
            default_clause => $column->default,
        } } ] } ],
    }};
}


######################################################################
######################################################################
sub alter_column {                       # ;
    my ($self, $catalog, $column, $action, $value) = @_;

    my $data_type = { %{ $column->type } };
    $data_type->{data_type} = delete $data_type->{type};

    # print Data::Dumper::Dumper ($column->default);
    +{ alter_table => {
        table_name => { name => $column->table->name, schema => $column->table->schema },
        alter_table_actions => [ { add_column => [ { column_definition => {
            column_name    => $column->name,
            %$data_type,
            not_null       => $column->not_null,
            default_clause => $column->default,
        } } ] } ],
    }};
}


######################################################################
######################################################################
sub table_row {                          # ;
    my ($self, $table) = @_;
    my @retval;
    my $table_name = { name => $table->name, schema => $table->schema };

    for my $row (@{ $table->table_row }) {
        push @retval, +{ statement_insert => {
            table_name => $table_name,
            (map +(column_list => $_), grep $_, $row->{columns}),
            insert_value_list => $row->{values},
        }};
    }


    @retval;
}


######################################################################
######################################################################

package SQL::Admin::Driver::Base::Decompose;

1;
