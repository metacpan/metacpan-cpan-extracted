package Persistence::Relationship::ToOne;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

use Abstract::Meta::Class ':all';
use base qw (Exporter Persistence::Relationship);
use Carp 'confess';

$VERSION = 0.01;

@EXPORT_OK = qw(to_one);
%EXPORT_TAGS = (all => \@EXPORT_OK);


=head1 NAME

Persistence::Relationship::ToOne - To one relationship

=head1 CLASS HIERARCHY

 Persistence::Relationship
    |
    +----Persistence::Relationship::ToOne

=head1 SYNOPSIS

    use Persistence::Relationship::ToOne ':all';

    #entity defintion
    my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');
    my $emp_entity = Persistence::Entity->new(
        name    => 'emp',
        alias   => 'ep',
        primary_key => ['empno'],
        columns => [
            sql_column(name => 'empno'),
            sql_column(name => 'ename', unique => 1),
            sql_column(name => 'job'),
            sql_column(name => 'deptno'),
        ],
    );

    my $dept_entity = Persistence::Entity->new(
        name    => 'dept',
        alias   => 'dt',
        primary_key => ['deptno'],
        columns => [
            sql_column(name => 'deptno'),
            sql_column(name => 'dname'),
            sql_column(name => 'loc')
        ],
    );

    $dept_entity->add_to_many_relationships(sql_relationship(target_entity => $emp_entity, join_columns => ['deptno'], order_by => 'deptno, empno'));
    $entity_manager->add_entities($dept_entity, $emp_entity);

    #object mapping

    package Employee;

    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';

    entity 'emp';
    column empno=> has('$.id');
    column ename => has('$.name');
    column job => has '$.job';
    to_one 'dept' => (
        attribute        =>  has ('$.dept', associated_class => 'Department'),
        cascade          => ALL,
        fetch_method     => EAGER,
    );

    package Department;

    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';

    entity 'dept';
    column deptno => has('$.id');
    column dname => has('$.name');
    column loc   => has('$.location');


=head1 DESCRIPTION

Represents to one relationship. 
Supports eager, lazy fetch, cascading operation (inert/update/delete).

=head1 EXPORT

to_one method by ':all' tag.

=head2 METHODS

=over

=cut

=item to_one

Create a new instance of to one relation.
Takes associated entity's id as parameters
and list of named parameters for Persistence::Relationship::OneToMany constructor.

    one_to_many 'wsus_user_service' => (
        attribute    => has('@.membership' => (associated_class => 'Membership')),
        fetch_method => EAGER,
        cascade      => ALL,
    );


=cut

sub to_one {
    my $package = caller();
    __PACKAGE__->add_relationship($package, @_);
}


=item deserialise_attribute

Deserialises relation attribute

=cut

sub deserialise_attribute {
    my ($self, $object, $entity_manager, $orm) = @_;
    my $entity = $entity_manager->entity($orm->entity_name);
    my $attribute = $self->attribute;
    #avoid cycles while have eager retrieval
    if (my $pending_value = $entity_manager->has_pending_operation($self->name)) {
        $attribute->set_value($object, $pending_value);
        return ;
    }

    my @rows = $entity->relationship_query(
        $self->name,
        ref($object) => $attribute->associated_class,
        $orm->column_values($object, $entity->primary_key)
    );

    if (@rows) {
        confess "relationhip " . $self->name . "to one returned " . (@rows) . " rows" if(@rows > 1);
        my $mutator = $attribute->mutator;
        $object->$mutator($rows[0]);
    }
}


=item insert

Inserts relationship data.

=cut

sub insert {
    my ($self, $orm, $entity, $dataset, $object) = @_;
    my $attribute = $self->attribute;
    my $value = $attribute->get_value($object) or return;
    $entity->relationship_insert($self->name, $dataset, $value);
}


=item merge

Merges relationship data. #what if lazy

=cut

sub merge {
    my ($self, $orm, $entity, $dataset, $object) = @_;
    my $value = $self->value($object);
    $entity->relationship_merge($self->name, $dataset, $value);
}



=item delete

Merges relationship data.

=cut

sub delete {
    my ($self, $orm, $entity, $dataset, $object) = @_;
    my $value = $self->value($object);
    $entity->relationship_delete($self->name, $dataset, $value);
}


1;

__END__

=back

=head1 SEE ALSO

L<Persistence::Relationship>
L<Persistence::Entity>
L<Persistence::Entity::Manager>
L<Persistence::ORM>

=head1 COPYRIGHT AND LICENSE

The Persistence::Relationship::ToOne module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, E<lt>adrian@webapp.strefa.pl</gt>

=cut

1;
