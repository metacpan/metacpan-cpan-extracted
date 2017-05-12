package SQL::Entity::Relationship;

use warnings;
use strict;
use Carp 'confess';
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);
use SQL::Entity::Condition;

$VERSION = '0.01';
use base 'Exporter';

@EXPORT_OK = qw(sql_relationship);
%EXPORT_TAGS = (all => \@EXPORT_OK);

use Abstract::Meta::Class ':all';

=head1 NAME

SQL::Entity::Relationship - Entities Relationship abstraction layer.

=head1 SYNOPSIS

    use SQL::Entity::Relationship ':all';
    use SQL::Entity::Column ':all';
    use SQL::Entity::Table;
    use SQL::Entity::Condition ':all';

    my $dept = SQL::Entity::Table->new(
        name    => 'dept',
        alias   => 'd',
        columns => [
            sql_column(name => 'deptno'),
            sql_column(name => 'dname')
        ],
    );
    my $emp  = SQL::Entity->new(
        name                  => 'emp',
        primary_key		  => ['empno'],
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
    ));

=head1 DESCRIPTION

Represents relationship between entities.

=head2 EXPORT

sql_relationship by all tag.

=head2 ATTRIBUTES

=over

=item name

Name of the relationship

=cut

has '$.name';


=item target_entity

=cut

has '$.target_entity' => (associated_class => 'SQL::Entity');


=item condition

=cut

has '$.condition' => (associated_class => 'SQL::Entity::Condition');


=item join_columns

=cut

has '@.join_columns';


=item order_by

=cut

has '$.order_by';


=back

=head2 METHODS

=over

=item initialise

=cut

sub initialise {
    my ($self) = @_;
    $self->name($self->target_entity->id)
        unless $self->name;
}


=item join_condition

Return join condition.

=cut

sub join_condition {
    my ($self, $entity, $bind_variables, $entity_condition) = @_;
    my $join_condition = $self->join_columns_condition($entity);
    my $condition = $self->condition;
    $condition = $condition && $join_condition
        ? $join_condition->and($condition)
        : $condition || $join_condition;
    $condition = $entity_condition ? $condition->and($entity_condition) : $condition;
    $condition;
}



=item join_condition_as_string

Return SQL condition fragment.

=cut

sub join_condition_as_string {
    my ($self, $entity, $bind_variables, $entity_condition) = @_;
    my $condition = $self->join_condition($entity, $bind_variables, $entity_condition);
    my $target_entity = $self->target_entity;
    my %query_columns = $entity->query_columns;
    $condition->as_string(\%query_columns, $bind_variables, $entity);
}


=item join_columns_values

Returns join columns values.

=cut

sub join_columns_values {
    my ($self, $entity) = @_;
    my $target_entity = $self->target_entity;
    if($entity->to_one_relationship($self->name)) {
        $target_entity = $entity;
        $entity =  $self->target_entity;
    } 
    my @join_columns = $self->join_columns or return;
    my @primary_key = $entity->primary_key or confess "primary key must be defined for entity " . $entity->name;
    
    my @result;
    for my $i (0 .. $#primary_key) {
        my $column = $entity->column($primary_key[$i])
            or confess "unknown primary key column: "  . $primary_key[$i] . " on " . $entity->name;
        push @result, $column;

        my $join_column = $target_entity->column($join_columns[$i])
            or confess "unknown foreign key column: " . $join_columns[$i] . " on " . $target_entity->name;
        push @result, $join_column;
    }
    @result;
    
}

=item join_columns_condition

Returns condition for join columns.

=cut

sub join_columns_condition {
    my ($self, $entity) = @_;
    my @condition = $self->join_columns_values($entity);
    SQL::Entity::Condition->struct_to_condition(@condition);
}


=item order_by_clause

Returns order by sql fragment.

=cut

sub order_by_clause {
    my ($self) = @_;
    my $order_by = $self->order_by;
    $order_by ? " ORDER BY ${order_by}" : "";
}


=item associate_the_other_end

Associated the other end.

=cut

sub associate_the_other_end {
    my ($self, $entity) = @_;
    my $target_entity = $self->target_entity;
    $target_entity->add_to_one_relationships(sql_relationship(
        name => ($entity->id || $entity->name),
        target_entity => $entity,
        condition     => $self->condition,
        ($self->join_columns ? (join_columns => [$self->join_columns ]) : ())
    ));
}


=item sql_relationship

Creates a new relation object.

=cut

sub sql_relationship {
    __PACKAGE__->new(@_);
}



1;

__END__


=back

=head1 SEE ALSO

L<SQL::Entity>
L<SQL::Entity::Column>

=head1 COPYRIGHT AND LICENSE

The SQL::Entity::Relationship module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut
