package SQL::Entity;

use warnings;
use strict;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);
use Storable qw(dclone);

$VERSION = 0.05;

use Abstract::Meta::Class ':all';
use Carp 'confess';
use SQL::Entity::Column ':all';
use SQL::Entity::Column::LOB ':all';
use SQL::Entity::Condition ':all';
use SQL::Entity::Index ':all';
use SQL::Entity::Relationship ':all';

use base qw(Exporter SQL::Entity::Table);

use constant THE_ROWID  => 'the_rowid';

@EXPORT_OK = qw(
  sql_relationship
  sql_column
  sql_lob
  sql_index
  sql_cond
  sql_and
  sql_or
);

%EXPORT_TAGS = (all => \@EXPORT_OK);


=head1 NAME

SQL::Entity - Entity sql abstraction layer.

=head1 CLASS HIERARCHY

 SQL::Entity::Table
    |
    +----SQL::Entity

=head1 SYNOPSIS

    use SQL::Entity;

    my $entity = SQL::Entity->new(
        id                    => 'emp',
        name                  => 'emp',
        unique_expression     => 'rowid',
        columns               => {
            emp_name => sql_column(name => 'ename'),
            emp_no   => sql_column(name => 'empno'),
        },
    );

    my($sql_text, $bind_variables) = $entity->query(
      sql_cond('emp_no', '>', '20')
      ->and(sql_cond('emp_name', 'NOT LIKE', 'HO%'))
    )

    # select from database
    .... do some stuff

    my ($sql_text, $bind_variables) = $entity->insert(
        emp_no   => '0',
        emp_name => 'Smith',
    );

    # insert row/s
    ... do some stuff

    my ($sql_text, $bind_variables) = $entity->update(
        { ename => 'Smith'},
        { empno => '20'} #pk values
    );

    # update row
    ... do some stuff

    my ($sql_text, $bind_variables) = $entity->delete(
        empno => '20'
    );
    # delete row/s
    ... do some stuff


    my $dept = SQL::Entity->new(
        name    => 'dept',
        columns => [
            sql_column(name => 'deptno'),
            sql_column(name => 'dname')
        ],
    );

    my $emp = SQL::Entity->new(
        name                  => 'emp',
        primary_key           => ['empno'],
        unique_expression     => 'rowid',
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
    );


    $emp->add_to_one_relationships(sql_relationship(
        target_entity => $dept,
        condition     => sql_cond($dept->column('deptno'), '=', $entity->column('deptno'))
        # or join_columns => ['deptno'],
    ));

    $emp->add_subquery_columns($dept->column('dname'));


=head1 DESCRIPTION

This class uses entity meta definition to generate different kinds of sql statmements.

=head2 EXPORT

  sql_column
  sql_lob   
  sql_index
  sql_cond
  sql_and
  sql_or by 'all' tag

=head2 ATTRIBUTES

=over

=item id

=cut

has '$.id';


=item query_from 

SQL fragment.

=cut

has '$.query_from';


=item query_from_helper

Code referebce that may transform query_from

=cut

has '&.query_from_helper';


=item columns

=cut

has '%.subquery_columns' => (
    item_accessor    => 'subquery_column',
    associated_class => 'SQL::Entity::Column',
    index_by         => 'id',
    the_other_end    => 'entity',
);


=item unique_expression

Expression that's value will be used to identifying the unique row in Entity.
It may be any column or pseudo column like ROWID for Oracle, 
or expression like PK_COLUMN1||PK_COLUMN2

=cut


has '$.unique_expression';


=item unique_row_column

Association to the column object that based on unique_expression.

=cut

has '$.unique_row_column';


=item to_one_relations

Association many_to_one, or one_to_one tables.

=cut

has '%.to_one_relationships' => (associated_class => 'SQL::Entity::Relationship', item_accessor => 'to_one_relationship', index_by => 'name');


=item to_many_relations

Association many_to_many, or one_to_many tables.
To many relation implicitly creates to one relation on the reflective entity.

=cut


has '%.to_many_relationships' => (
    associated_class => 'SQL::Entity::Relationship',
    item_accessor    => 'to_many_relationship',
    index_by         => 'name',
    on_change        => sub {
        my ($self, $attribute, $scope, $value, $key) = @_;
        if($scope eq 'mutator') {
            foreach my $relation (values %$$value) {
                $relation->associate_the_other_end($self);
            }
            
        } else {
            $$value->associate_the_other_end($self);
        }
        $self;
    }
);


=item sql_template_parameters

Allows use mini language variable,

    SELECT t.* FROM
    (SELECT t.* FROM tab t WHERE t.col1 = [% var1 %]) t

=cut

has '%.sql_template_parameters' => (item_accessor => 'sql_template_parameter');


=item dml_generator

Represents class that will be used to generate DML statements.
SQL::DMLGenerator by default.

=cut

{
    my %loaded;
    has '$.dml_generator' => (
        default => 'SQL::DMLGenerator',
        on_read => sub {
            my ($self, $attribute, $scope, $value) = @_;
            my $result = $attribute->get_value($self);
            unless ($loaded{$result}) {
                my $module = $result;
                $module =~ s/::/\//g;
                $module  .= ".pm";
                eval {
                    require $module;
                    $loaded{$result} = 1;
                }
            }
            $result;
        }
    );
}


=back

=head2 METHODS

=over

=item initialise

=cut

sub initialise {
    my ($self) = @_;
    $self->SUPER::initialise();
    unless  ($self->id) {
        my $schema = $self->schema;
        $self->set_id(($schema ? $schema ."." :"") .  $self->name);
    }
    $self->initialise_unique_row_column;
}


=item initialise_unique_row_column

=cut

sub initialise_unique_row_column {
    my ($self) = @_;
    unless ($self->unique_expression) {
        my @pk = $self->primary_key;
        confess "unique_expression or primary_key is required"
        unless(@pk);
        my $alias = @pk > 1 ? $self->alias : "";
        $self->unique_expression( join "||", @pk);
    }
    
    if ($self->unique_expression) {
        my $unique_expression = $self->unique_expression;
        $self->set_unique_row_column(
            sql_column(
                ($unique_expression =~ m/[^\w]/ ? 'expression' :  'name') => $self->unique_expression,
                id         => THE_ROWID() ,
                table      => $self,
                updatable  => 0,
                insertable => 0,
            )
        );
    }
}



=item set_relationship_join_method

Sets join methods

=cut

sub set_relationship_join_method {
    my ($self, $column, $method, $join_methods) = @_;
    my $table = $column->table;
    if ($table && $table ne $self) {
        return if $join_methods->{$table->id};
        $join_methods->{$table->id} = $method;
    }
}


=item query

Returns sql statement and bind variables,
Takes optionally array ref of the requeted columns (undef returns all entity columns), condition object, bind_variables reference

    my ($sql, $bind_variables) = $entity->query(undef, 
      sql_cond('empno', '>', '20')->and(sql_cond('dname', 'NOT LIKE', 'HO%'))
    );

=cut


sub query {
    my ($self, @args) = @_;
    my ($sql, $bind_variables) = $self->SUPER::query(@args);
    $sql = $self->parse_template_parameters($sql);
    ($sql, $bind_variables);
}


=item lock

Returns sql that locks all rows that meets passed in condition
It uses SELECT ... FOR UPDATE pattern.
Takes optionally array ref of the requeted columns, condition object, bind_variables reference

    my ($sql, $bind_variables) = $entity->lock(undef, 
      sql_cond('empno', '>', '20')->and(sql_cond('dname', 'NOT LIKE', 'HO%'))
    );

=cut

sub lock {
    my ($self, @args) = @_;
    my ($sql, $bind_variables) = $self->SUPER::query(@args);
    $sql .= " FOR UPDATE";
    ($sql, $bind_variables);
}


=item insert

Returns insert sql statement and bind variables

    my ($sql, $bind_variables) = $entity->insert(
        dname  => 'hr',
        deptno => '10',
        ename  => 'adi',
        empno => '1',
    );

=cut

sub insert {
    my ($self, %args) = @_;
    my @columns = $self->insertable_columns;
    my %field_values;
    foreach my $column (@columns) {
        my $name = $column->name;
        $field_values{$name} = $args{$name};
    }
    my $dml_generator = $self->dml_generator;
    $dml_generator->insert($self, \%field_values);
}


=item update

Returns update sql statement and bind variables

    my ($sql, $bind_variables) = $entity->update(
        {dname  => 'hr',
        deptno => '10',
        ename  => 'adi',
        empno => '1',},
        {the_rowid => 'AAAMgzAAEAAAAAgAAB'},
    );

=cut

sub update {
    my ($self, $fields_values, $conditions) = @_;
    my @columns = $self->updatable_columns;
    my %field_values;
    
    foreach my $column (@columns) {
        my $name = $column->name;
        next unless exists($fields_values->{$name});
        $field_values{$name} = $fields_values->{$name};
    }

    my $dml_generator = $self->dml_generator;
    $dml_generator->update($self, \%field_values, $conditions);

}


=item delete

Returns deletes sql statement and bind variables

    my ($sql, $bind_variables) = $entity->delete(empno => '1');

=cut

sub delete {
    my ($self, @args) = @_;
    my $dml_generator = $self->dml_generator;
    $dml_generator->delete($self, @args);
}


=item unique_condition_values

Returns condition that uniquely identify the entity.
Takes the entity fields values, and validation flag.
If validation flag is true, then exception will be raise if there are not condition values.

=cut

sub unique_condition_values {
    my ($self, $fields_values, $validate) = @_;
    my $column = $self->unique_row_column;
    my %result;
    if ($fields_values && $column && (defined $fields_values->{$column->id} || ($column->name && $fields_values->{$column->name}))) {
        my $column_name = $column->name || $column->expression;
        my $value = ($fields_values->{$column->id} || $fields_values->{$column_name});
        $result{$column_name} = $value if $value;

    } else {
        my @pk = $self->primary_key;
        for my $column (@pk) {
            next unless exists $fields_values->{$column};
            my $value = $fields_values->{$column};
            $result{$column} = $value if defined $value;
        }
    }
    unless (%result) {
        my @columns = values %{$self->columns};
        for my $column (@columns) {
            if($column->unique) {
                my $column_name= $column->name;
                my $value = $fields_values->{$column_name};
                if (defined $value) {
                    $result{$column_name} = $value;
                    last;
                }
            }
        }
        confess "cant find unique value: on dataset: \n\t" . join ",\n\t", map { $_ . " => " . ($fields_values->{$_} || '')} keys %$fields_values
            if !(%result) && $validate;
    }
    
    wantarray ? (%result) : \%result;
}


=item selectable_columns

Retuns list of columns that can be selected.
Takes requested columns as parameter.

=cut

sub selectable_columns {
    my ($self, $requested_columns) = @_;
    my $subquery_columns = $self->subquery_columns;
    my @result = ($self->unique_row_column, (values %$subquery_columns), $self->SUPER::selectable_columns($requested_columns));
    if (@$requested_columns) {
        my %column_hash = map {$_->id, $_} @result;
        return map {$column_hash{$_} ? ($column_hash{$_}) : ()} @$requested_columns;
    }
    @result;
}



=item from_sql_clause

Returns FROM .. sql fragment without join.

=cut

sub from_sql_clause {
    my ($self, $join_methods) = @_;
    my $query_from = $self->query_from;
    my $query_from_helper = $self->query_from_helper;
    $query_from = $query_from_helper->($self)
        if $query_from_helper;
    my $alias = $self->alias;
    my $name = $self->name;
    ($query_from
      ? "( $query_from )" . $self->from_clause_alias
      : $self->SUPER::from_clause_params($join_methods))
}


=item from_clause_params

Returns FROM sql frgments with join clause.

=cut

sub from_clause_params {
    my ($self, $join_methods) = @_;
    $self->from_sql_clause($join_methods) . $self->join_clause($join_methods);
}

 
=item join_clause

Returns "JOIN ... " sql fragment for all to one relationship

=cut

sub join_clause {
    my ($self, $join_methods) = @_;
    my $result = '';
    foreach my $k (keys %$join_methods) {
        my $relation = ($self->to_one_relationship($k) || $self->to_many_relationship($k)) or return '';
        my $target_entity = $relation->target_entity;
        my $join_method = $join_methods->{$k};
        next if $join_method ne 'JOIN';
        my $condition = $relation->condition;
        my %query_columns = $target_entity->query_columns;
        $result .= "\n${join_method} "
        . $target_entity->from_clause_params($join_methods)
        . " ON (" . $relation->join_condition_as_string($self) . ")";
        
    }
    $result;
}


=item relationship_query

Returns sql query + bind_variables to many relationship

=cut

sub relationship_query {
    my ($self, $relation_name, @args) = @_;
    my $relationship = $self->relationship($relation_name)
        or confess "cant find relationship ${relation_name}";
    my $entity = $relationship->target_entity;
    my ($sql, $bind_variables) = $entity->query();
    my $condition = $self->condition_converter(@args);
    $sql .= "\nWHERE EXISTS (SELECT 1 FROM "
        . $self->from_sql_clause
        . " WHERE " . $relationship->join_condition_as_string($self, $bind_variables, $condition) .")"
        . $relationship->order_by_clause;
    ($sql, $bind_variables);
}


=item normalise_field_names

Replaces all keys that are passed in as alias to column name
for instance we have the folllowing SQL: SELECT ename as name, id, loc FROM emp
name will be replaced to ename.

=cut

sub normalise_field_names {
    my ($self, @args) = @_;
    my %columns = $self->query_columns;
    my @result;
    for(my $i = 0; $i < $#args; $i +=2) {
        my $column = $args[$i];
        push @result, (($columns{$column} ? $columns{$column}->name : $column), $args[$i + 1]);
    }
    @result
}


=item relationship

Return relationship object, takes relationship name.

=cut

sub relationship {
    my ($self, $relation_name) = @_;
    my $result = $self->to_many_relationship($relation_name) || $self->to_one_relationship($relation_name) || '';
    confess "cant find relationship $result" unless $result;
    $result;
}

=item query_columns

All columns that belongs to this object.

=cut


sub query_columns {
    my ($self) = @_;
    (THE_ROWID() =>  $self->unique_row_column, $self->subquery_columns, $self->SUPER::query_columns);
}


=item condition_converter

Converts passed in argumets to condition object

=cut

sub condition_converter {
    my ($self, @args) = @_;
    (@args > 1)
        ? SQL::Entity::Condition->struct_to_condition(@args)
        : $args[0];
}


=item parse_template_parameters

Parses template variables.

=cut

sub parse_template_parameters {
    my ($self, $sql) = @_;
    my $sql_template_parameters = $self->sql_template_parameters or return $sql;
    for my $k (keys %$sql_template_parameters) {
        my $value = $sql_template_parameters->{$k};
        $sql =~ s/\[\%\s+$k\s+\%\]/$value/g;
    }
    $sql;
}


=item clone

Clones this entity

=cut

sub clone {
    my $self = shift;
    dclone $self;
}

1; 

__END__

=back

=head1 SEE ALSO

L<SQL::Entity::Table>
L<SQL::Entity::Index>
L<SQL::Entity::Column>
L<SQL::Entity::Condition>

=head1 COPYRIGHT AND LICENSE

The SQL::Entity module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

See also B<DBIx::Connection> B<DBIx::QueryCursor> B<DBIx::PLSQLHandler>.

=cut
