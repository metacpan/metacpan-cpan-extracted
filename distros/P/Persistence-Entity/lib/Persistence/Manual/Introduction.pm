use strict;
use warnings;

use vars qw($VERSION);

$VERSION = 0.02;

=head1 NAME

Persistence::Manual::Introduction - Introduction to Persistence::Entity. 

=head1 INTRODUCTION

We'll take a thorough look at the process of developing entities,
perl classes  and mapping between them to a relational database.

=head1 ENTITY

Entity represents logical unit of data in the database.
It doesn't need to be just a simple mapping to a table, but it may represent comlex
SQL epressions, with subqueries, joins, etc, this is especailly important to limit database
calls for all those information to one call, rather then using separtes cursors with many fetch executions.

Examples of entities:

    my $dept_entity = Persistence::Entity->new(
        name    => 'dept',
        alias   => 'dt',
        primary_key => ['deptno'],
        columns => [
            sql_column(name => 'deptno'),
            sql_column(name => 'dname'),
        ]
    );

    my $emp_entity = Persistence::Entity->new(
        name    => 'emp',
        alias   => 'ur',
        primary_key => ['empno'],
        columns => [
            sql_column(name => 'empno'),
            sql_column(expression => 'SYSDATE - dob', alias => 'age'),
            sql_column(name => 'ename', unique => 1),
            sql_column(name => 'job'),
            sql_column(name => 'deptno'),
        ],
        subquery_columns => [
            $dept_entity->column('dname'),
        ]
    );

    $entity_manager->add_entities($dept_entity, $emp_entity);


=head1 OBJECT TO RELATIONAL DATABASE MAPPING

The purpose of an object relational mapping is to provide programmers with a simpler mechanism for accessing
and changing data using plain perl classes, so when creating a new object or changing existing one
it must be inserted into the database or synchronized accordingly.
The process of coordinating the data represented by a object instance with the database is called persistence.

You have to delcare mapping between you class and entity, then you can use your classes like any other perl classes.

Class itself shouldn't be aware about database mapping and database operation underneath, thus
you interact with the entity manager to persist, update, remove, locate, and query for objects.
The entity manager is responsible for automatically managing the object' state.
It takes care of managing the object in transactions and persisting its state to the database.


    $entity_manager->begin_work;
    eval {
        my $emp = Employee->new(id => 100, name => 'Scott');
        $entity_manager->insert($emp);

        #you can delcare mapping between many object to the same entity (for different inheritance strategy)
        #so that find takes entity_name, class_name as two first parameters.

        my @emp = $entity_manager->find(emp => 'Employee', deptnp => 10);
        for my $emp (@emp) {
            $emp->set_sallary($emp->salary + $emp->salary * 0.05)  ;
            $entity_manager->update($emp);
        }
        $entity_manager->commit;
    }
    $entity_manager->rollback if $@;


=head2 The Programming Model

=over

=item Classes defined with Meta Object Protocol

This module suppports adapters to different MOP classes so that
it may be easily extended by adding adapter class that implements/extends Persistence::Attribute interface.

Persistence::Attribute::AMCAdapter is default adapter class that supports Abstract::Meta::Class.

    package Employee;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    column empno => has('$.id') ;
    column ename => has('$.name') ;
    column job => has('$.job') ;


=item Plain perl classes

    use Persistence::ORM;

    Persistence::ORM->new(
        mop_attribute_adapter => 'Persistence::Attribute::AMCAdapter',
        entity_name           => 'emp',
        class                 => 'Employee',
        columns               => {
            empno => {name => 'id'},
            ename => {name => 'name'},
            job   => {name => 'job'},
        }
    );

    package Employee;

    sub new {
        my $class = shift;
        bless {@_}, $class;
    }


    sub id {
        shift()->{id};
    }

    sub set_id {
        my ($self, $value) = @_;
        $self->{id} = $value;
        $self;
    }

    sub name {
        shift()->{name};
    }

    sub set_name {
        my ($self, $value) = @_;
        $self->{name} = $value;
        $self;
    }

    #or setter/getter in one approach

    sub job {
        my ($self, $value) = @_;
        $self->{job} = $value if (@_ > 1);
        $self->{job};
    }


=item XML Mapping File

If you do not want to interact directly with ORM or Entity meta protocal to declare map between your class and entity,
or entity and database you can alternatively use an XML mapping file to declare this metadata.

Perl class

    package Employee;
    use Abstract::Meta::Class ':all';
    has '$.id';
    has '$.name';
    has '$.salary';
    has $.job';


XML injection of the persistence metadata.

    use Persistence::Meta::XML;
    my $meta = Persistence::Meta::XML->new(persistence_dir => 'meta/');
    $meta->inject('persistence.xml');


XML definitions:

    persistence.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <persistence name="test"  connection_name="test" >
        <entities>
            <entity_file  file="emp.xml"  />
        </entities>
        <mapping_rules>
            <orm_file file="Employee.xml" />
        </mapping_rules>
    </persistence>

    emp.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <entity name="emp" alias="e">
        <primary_key>empno</primary_key>
        <columns>
            <column name="empno" />
            <column name="ename" unique="1" />
            <column name="sal" />
            <column name="job" />
            <column name="deptno" />
        </columns>
    </entity>


    Employee.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <orm entity="emp"  class="Employee" >
        <column name="empno"  attribute="id" />
        <column name="ename"  attribute="name" />
        <column name="job"    attribute="job" />
        <column name="sal"    attribute="salary" />
    </orm>

=back

=cut
