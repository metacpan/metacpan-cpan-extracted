use strict;
use warnings;

use vars qw($VERSION);

$VERSION = 0.02;

=head1 NAME

Persistence::Manual::EntityManager - Persistence actions..

=head1 DESCRIPTION

Entity manager is responsible of coordinating the data represented by a object instance with the database.

Persisistence::Entity::Manager tracks objects state by caching to avoid the additional database calls at the synchronization stage.
This class synchronises object by interacting with entities (L<Persistence::Entity>), object to entity mappings (L<Persistience::ORM>)
and DBMS tier (L<DBIx::Connection>).


    my $entity_manager = Persistence::Entity::Manager->new(
        name            => 'my_manager'
        connection_name => 'my_connection'
    );

    $entity_manager->add_entities(SQL::Entity->new(
        name                  => 'emp',
        primary_key          => ['empno'],
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
    ));

    DBIx::Connection->new(
      name     => 'my_connection',
      dsn      => 'dbi:Oracle:host:port/INSTANCE',
      username => 'username',
      password => 'password',
    ); 


=head2 Persistence Options

Objects that interact with an Entity Manager may be in I<atached> and I<detached> state. In first case copy of object state is store in
entity cache, in other words when an object  is attached to an entity manager,
the manager tracks state changes to that object and synchronizes those changes to the database.

By default the B<persitence_mangement> options is set to transaction
that means that when transation completes all objects state will be flushed and then detached from cache.

You may want to change that behavious by setting the persitence_mangement option to extended,
so in that case entity manager will cache all object unless expliciitly detach_all or detach is issued.

Note:
Using this option you must ensure that there are eought space and obsolete objects are not stored in the entity manager cache by
calling detching the obsolete objects.

If you don't want cache objects state then set persitence_mangement to undef, but 
then there will be extra database calls to get object state from database for update, delete ad hoc.

Note:
By default entity manager uses auto commit mode, so if you want to use transaction
you must start a new transation explictly by calling begin_work


    $entity_manager->begin_work;
    eval {
        #do stuff
        $entity_manager->commit;
    }
    $entity_manager->rollback if $@;


=cut

=head2 Persisitence Operation

=over

=item Obtaining an  entity manager

Once the entity manager is created you can obtain it by calling:

    my $entity_manager = Persistence::Entity::Manager->manager('entity_manager_name');

=back

=head2 Interacting with an Enity Manager

Lets discuess the basic operation using the following code snippet, that
declare database entity emp, and object Employee with mapping to emp entity.


    my $entity_manager = Persistence::Entity::Manager->new(
        name            => 'my_manager'
        connection_name => 'my_connection'
    );

    $entity_manager->add_entities(SQL::Entity->new(
        name                  => 'emp',
        primary_key          => ['empno'],
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
    ));

    {
        package Employee;
        use Abstract::Meta::Class ':all';
        use Persistence::ORM ':all';

        entity 'emp';
        column empno => has('$.no') ;
        column ename => has('$.name');
    }


=over

=item Finding Objects

The entity manager provides two mechanisms for locating objects in your database.
The first usses find method, whereas the secound uses query method.


B<find> method returns list of objects|hash_ref that are meeting conditions criteria (constraint).
and takes entity_name, class_nane, condition constraint.
You have to pass clas name because one entity may have more then one object mapping.
Note: If class name has the ORM mapping, then name parameters
must be the object attributs if using Condition object always should use entity columns.


    my ($emp) = $entity_manager->find(emp => 'Employee', name => 'adrian');
    or
    my @emp = $entity_manager->find(emp => 'Employee', sql_cond('ename', 'LIKE', 'a%'));


B<query> object returns Query object that allows us navigating through resultset.
and takes entity_name, class_nane
You have to pass clas name because one entity may have more then one object mapping.
Note: If class name has the ORM mapping, then name parameters
must be the object attributs if using Condition object always should use entity columns.


    my $query = $entity_manager->query(emp => 'Employee');
    $query->set_offset(20);
    $query->set_limit(5);


Execute methods return list of objects|hash_ref that are meeting conditions criteria (constraint),
takes array_ref of projections columns, condition constraint.


    my @emp = $query->execute(undef, deptno => '10');
    my @emp = $query->execute(['ename'], deptno => '10');


=item Locking Objects

B<lock> methods locks all rows that are part of result of that method,
Itreturns list of objects|hash_ref that are meeting conditions criteria (constraint).
and takes entity_name, class_nane, condition constraint.


    my @emp = $entity_manager->lock(emp => 'Employee', sql_cond('ename', 'LIKE', 'a%'));


=item Inserting Objects

Adds object to databse.


    my $emp = Employee->new(id => 1, name => 'Scott');
    $entity_manager->insert($emp);


=item Updating Objects

Updates object in databse.


    my ($emp) = $entity_manager->find(emp => 'Employee', name => 'adrian');
    $emp->set_job('manager');
    $entity_manager->update($emp);


=item Merging Objects

Merges object to databse, that means if objects doesn't exist in database, object is inserted, otherwie updated.


    my $emp = Employee->new(id => 3, name => 'Scott');
    $entity_manager->merge($emp);


=item Removing Objects

Removes object from database.


    my ($emp) = $entity_manager->find(emp => 'Employee', name => 'adrian');
    $entity_manager->delete($emp);


=item Refreshing Objects

Refreshs object state from databsae, overwrties current object state.


    my ($emp) = $entity_manager->find(emp => 'Employee', name => 'adrian');
    $entity_manager->refresh($emp);

=back

=cut
