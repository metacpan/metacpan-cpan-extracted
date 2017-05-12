use strict;
use warnings;


=head1 NAME 

Persistence::Manual::Relationship - Object relationships

=head1 DESCRIPTION

This manual coveres relationships mappings.

At first stage we will defining relationship between entities,
then at secound stage relationship between objects including.

=head2 Entities Relationships

From database entities point of view we may define only direct relationships: to_many and to_one.
There was no point introducing at entity level many to many as it is technicaly
combination of two  one to many relationships with technical join table.

Let's consider the following database entities relationships


    -----------     ------------     -----------     ------------      ------------
    | project |     | emp_proj |     |   emp   |     |  dept    |     | address   |
    |# projno |---|<|# projno  |>|---|# empno  |     |# deptno  |-----|# id       |
    |0 name   |     |# empno   |     |0 name   |     |0 dname   |     |0 town     |
    |         |     |          |     |0 deptno |>----|0 addr_id |     |0 postcode |
    |         |     |          |     |         |     |          |     |0 location |
    ----------      ----------       ----------      ------------     ------------


    So we're having here the following relationships:
    
    - emp entity has many to one relationship with dept entity - thus dept entity has one to many relationship with emp entity
    - entity dept has one to one relationship with address entity- thus address entity has to one relationship with dept entity
    (in this case physical to_one relationship depens on where we place foreign key)
    - emp entity has many to many relationship with project and vice versa, but this is not direct relationship,
    however we can breaks it down to two direct one to many relationships with a technical join table.
       - emp has one to many relationship with emp_proj
       - project one to many relationship with emp_proj



The following code defines our relationship examples.

    use Persistence::Entity::Manager;
    use Persistence::ValueGenerator::TableGenerator;
    use Persistence::Entity ':all';

    ####  value generators
    table_generator 'project_gen' => (
        entity_manager_name      => "my_manager",
        table                    => 'seq_generator',
        primary_key_column_name  => 'pk_column',
        primary_key_column_value => 'projno',
        value_column             => 'value_column',
        allocation_size          =>  5,
    );

    table_generator 'emp_gen' => (
        entity_manager_name      => "my_manager",
        table                    => 'seq_generator',
        primary_key_column_name  => 'pk_column',
        primary_key_column_value => 'empno',
        value_column             => 'value_column',
        allocation_size          =>  5,
    );

    my $project_entity = Persistence::Entity->new(
        name    => 'project',
        alias   => 'pr',
        primary_key => ['projno'],
        columns => [
            sql_column(name => 'projno'),
            sql_column(name => 'name', unique => 1),
        ],
        value_generators => {projno => 'project_gen'},
    );

    my $project_emp =  Persistence::Entity->new(
        name    => 'emp_project',
        alias   => 'ep',
        primary_key => ['projno', 'empno'],
        columns => [
            sql_column(name => 'projno'),
            sql_column(name => 'empno'),
        ],
    );

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
        value_generators => {empno => 'emp_gen'}, 
    );


    my $dept_entity = Persistence::Entity->new(
        name    => 'dept',
        alias   => 'dt',
        primary_key => ['deptno'],
        columns => [
            sql_column(name => 'deptno'),
            sql_column(name => 'dname', unique => 1),
            sql_column(name => 'addr_id'),
        ],
    );


    my $address_entity = Persistence::Entity->new(
        name    => 'address',
        alias   => 'ar',
        primary_key => ['id'],
        columns => [
            sql_column(name => 'id'),
            sql_column(name => 'loc'),
            sql_column(name => 'town'),
            sql_column(name => 'postcode'),
        ],
    );

    #relationsips definition here

    $project_entity->add_to_many_relationships(
        sql_relationship(target_entity => $emp_project_entity,join_columns => ['projno'], order_by => 'projno, empno')
    );

    $emp_entity->add_to_many_relationships(
        sql_relationship(target_entity => $emp_project_entity, join_columns => ['empno'], order_by => 'empno, projno')
    );


    $dept_entity->add_to_many_relationships(
        sql_relationship(target_entity => $emp_entity, join_columns => ['deptno'], order_by => 'deptno, empno')
    );

    $dept_entity->add_to_one_relationships(
        sql_relationship(target_entity => $address_entity, join_columns => ['addr_id'])
    );

    $entity_manager->add_entities($emp_project_entity, $emp_entity, $project_entity, $dept_entity, $address_entity);


Note:
When adding to_many relationsnship,on the other side reflective to_one relationship. is created automaticaly.

=head2 Objects Relationships

From database entities point of view we may define the following relationships.

=over

=item one_to_one

An example of a one-to-one relationship is one between a Department object
and an Address object. In this example, each Department has exactly one Address,
and each Address has exactly one Department.

    package Address;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    entity 'address';
    column id  => has('$.id');
    column loc  => has('$.location');
    column town => has('$.town');
    column postcode  => has('$.postcode');


    package Department;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    entity 'dept';
    column deptno   => has('$.id');
    column dname    => has('$.name');
    to_one 'address' => (
        attribute        =>  has ('$.address', associated_class => 'Address'),
        cascade          => ALL,
        fetch_method     => EAGER,
    );


=item many_to_one

An example of a many-to-one relationship is one between an Employee object
and a Department  object. In this example, each Employee has exactly one Department,
and each Department has many Employees.


    package Employee;
    use Abstract::Meta::Class ':all';
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
    use Persistence::ORM ':all';

    entity 'dept';
    column deptno   => has('$.id');
    column dname    => has('$.name');

Note: Bidirectional relationship in this case requires reference on Dept object:

    one_to_many 'emp' => (
        attribute    => has('@.employees' => (associated_class => 'Employee')),
        fetch_method => EAGER,
        cascade      => ALL,
    );


=item one_to_many

An example of a one-to-many relationship is one between a Department object
and Employees  objects. In this example, each Department has  many Employees 
and each Employee has exactly one Department 


    package Department;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    entity 'dept';
    column deptno   => has('$.id');
    column dname    => has('$.name');
    one_to_many 'emp' => (
        attribute    => has('@.employees' => (associated_class => 'Employee')),
        fetch_method => EAGER,
        cascade      => ALL,
    );

    package Employee;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    entity 'emp';
    column empno=> has('$.id');
    column ename => has('$.name');
    column job => has '$.job';

Note: Bidirectional relationship in this case requires reference on Employee object:

    to_one 'dept' => (
        attribute        =>  has ('$.dept', associated_class => 'Department'),
        cascade          => ALL,
        fetch_method     => EAGER,
    );


=item many_to_many

An example of a mant to mant relationship  is one between an Employee and a Project.
A Employee can be associated to many projects and each Projects has many Employees.
Many to many relationship uses join table.


    package Employee;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    entity 'emp';
    column empno=> has('$.id');
    column ename => has('$.name');
    column job => has '$.job';

    many_to_many 'project' => (
        attribute        => has('%.projects' => (associated_class => 'Project'), index_by => 'name'),
        join_entity_name => 'emp_project',
        fetch_method     => LAZY,
        cascade          => ALL,
    );

    package Project;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    entity 'project';
    column projno => has('$.id');
    column name => has('$.name');


=back

=cut
