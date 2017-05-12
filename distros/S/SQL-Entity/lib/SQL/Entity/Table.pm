package SQL::Entity::Table;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = 0.02;

use Abstract::Meta::Class ':all';
use Carp 'confess';
use SQL::Entity::Column;

=head1 NAME

SQL::Entity::Table - Database table abstraction

=head1 SYNOPSIS

    use SQL::Entity::Table;
    use'SQL::Entity::Column ':all';

    my $table = SQL::Entity::Table->new(
        name => 'emp'
        columns => [sql_column(name => 'empno')]
    );

    my ($sql) = $table->query;

    my $dept = SQL::Entity->new(
        name    => 'dept',
        alias   => 'd',
        columns => [
            sql_column(name => 'deptno'),
            sql_column(name => 'dname')
        ],
    );

    my $emp = SQL::Entity->new(
        name                  => 'emp',
        primary_key           => ['empno'],
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
    );

    $emp->add_to_one_relationships(sql_relationship(
        table     => $dept,
        condition => sql_cond($dept->column('deptno'), '=', $entity->column('deptno'))
    ));


=head1 DESCRIPTION

Represents database table definition.

=head2 EXPORT

None.

all - exports sql_column method

=head2 ATTRIBUTES

=over

=item name 

=cut

has '$.name';


=item schema

Table schema name

=cut

has '$.schema';


=item primary_key

=cut

has '@.primary_key';


=item alias

=cut

has '$.alias';


=item columns

=cut

has '%.columns' => (
    item_accessor    => 'column',
    associated_class => 'SQL::Entity::Column',
    index_by         => 'id',
    the_other_end    => 'table',
);


=item lobs

=cut

has '%.lobs' => (
    item_accessor    => 'lob',
    associated_class => 'SQL::Entity::Column::LOB',
    index_by         => 'id',
    the_other_end    => 'table',
);


=item indexes

=cut

has '%.indexes' => (
    item_accessor    => '_index',
    associated_class => 'SQL::Entity::Index',
    index_by         => 'name',    
);


=item order_index

Index name that will be used to enforce order of the result.

=cut

has '$.order_index';

=back

=head2 METHODS

=over

=item initialise

=cut

sub initialise {
    my ($self) = @_;
    $self->set_alias($self->name) unless $self->alias;
}


=item unique_columns

Returns list of unique columns

=cut

sub unique_columns {
    my ($self) = @_;
    (grep { $_->unique } values %{$self->columns});
}


=item query

Returns sql statement and bind variables,
Takes optionally array ref of the requeted columns, condition object, bind_variables reference

=cut

sub query {
    my ($self, $requested_columns, $condition, $bind_variables, $join_methods) = @_;
    $requested_columns ||=[];
    $bind_variables ||= [];
    $join_methods ||= {};
    my $where_clause = $self->where_clause($condition, $bind_variables, $join_methods);
    my $stmt = $self->select_clause($requested_columns, $join_methods)
    . $self->from_clause($join_methods)
    . $where_clause
    . $self->order_by_clause;
    wantarray ? ($stmt, $bind_variables) : $stmt;
}


=item count

Retiurn sql and bind variables that returns number of rows for passed in condition,

=cut

sub count {
    my ($self, $condition, $bind_variables, $join_methods) = @_;
    $bind_variables ||= [];
    $join_methods ||= {};
    my $where_clause = $self->where_clause($condition, $bind_variables, $join_methods);
    my $stmt = "SELECT COUNT(*) AS count"
    . $self->from_clause($join_methods) 
    . $where_clause;
    wantarray ? ($stmt, $bind_variables) : $stmt;
}


=item from_clause

Returns "FROM .... " SQL fragment

=cut

sub from_clause {
    my ($self, $join_methods) = @_;
    "\nFROM "
    . $self->from_clause_params($join_methods)
}


=item from_clause_params

Returns FROM operand " table1  " SQL fragment

=cut

sub from_clause_params {
    my ($self) = @_;
    my $schema = $self->schema;
    ($schema ? $schema . "." : "")
    . $self->name
    . $self->from_clause_alias;
}


=item from_clause_alias

Returns table alias

=cut

sub from_clause_alias {
    my ($self) = @_;
    my $alias = $self->alias;
   ($alias  && $self->name ne $alias ? " $alias" : '')
}


=item select_clause

Returns " SELECT ..." SQL fragment

=cut

sub select_clause {
    my ($self, $requested_columns, $join_methods) = @_;
    "SELECT "
    . $self->select_hint_clause
    . join ",\n  ", map { $_->as_string($self, $join_methods) } $self->selectable_columns($requested_columns);
}


=item selectable_columns

Returns list of column that can be used in select clause

=cut

sub selectable_columns {
    my ($self, $requested_columns) = @_;
    confess unless $requested_columns;
    my $columns = $self->columns;
    if(@$requested_columns) {
        return map { $columns->{$_} ? ($columns->{$_}) : () } @$requested_columns;
    }
    
    $self->columns ? (values %$columns) : (); 
}


=item insertable_columns

Returns list of column that can be used in insert clause

=cut

sub insertable_columns {
    my ($self) = @_;
    my $query_columns = $self->query_columns;
    map {
        my $column = $query_columns->{$_};
        ($column->insertable ? $column : ()) }  keys %$query_columns;
}


=item updatable_columns

Returns list of column that can be used in update clause

=cut

sub updatable_columns {
    my ($self) = @_;
    my $query_columns = $self->query_columns;
    map {
        my $column = $query_columns->{$_};
        ($column->updatable ? $column : ()) }  keys %$query_columns;
}


=item query_columns

Returns hash_ref with all columns that belongs to this object.

=cut

sub query_columns {
    my ($self) = @_;   
    $self->columns;
}


=item where_clause

Returns " WHERE  ..." SQL fragment

=cut

sub where_clause {
    my ($self, $condition, $bind_variables, $join_methods) = @_;
    return "" unless $condition;
    confess "should have condition object"
        if ($condition && ref($condition) ne 'SQL::Entity::Condition');
    my %query_columns = $self->query_columns;
    "\nWHERE " .  $condition->as_string(\%query_columns, $bind_variables, $self, $join_methods);
    
}


=item index

Returns order_index object, if order_index is not set then the first index will be seleted.

=cut

sub index {
    my $self = shift;
    my $order_index = $self->order_index;
    unless ($order_index) {
        my $indexes = $self->indexes or return;
        ($order_index) = (keys %$indexes) or return;
    }
    $self->_index($order_index);
}


=item select_hint_clause

Return hinst cluase that will be placed as SELECT operand

=cut

sub select_hint_clause {
    my ($self) = @_;
    ""
}


=item order_by_clause

Returns " ORDER BY ..." SQL fragment

=cut

sub order_by_clause {
    my ($self) = @_;
    my $index = $self->index or return "";
    " ORDER BY " . $index->order_by_operand($self);
}


__END__

=back

=head1 SEE ALSO

L<SQL::Query>
L<SQL::Entity>
L<SQL::Entity::Column>

=head1 COPYRIGHT AND LICENSE

The SQL::Entity::Table module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut
