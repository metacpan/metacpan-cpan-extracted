use strict;
use warnings;

use Test::More tests => 15;
use Test::DBUnit connection_name => 'test';

my $class;

BEGIN {
    $class = 'Persistence::Entity';
    use_ok($class, ':all');
    use_ok('Persistence::Entity::Manager');
}

my $emp_entity = $class->new(
    name    => 'emp',
    alias   => 'ur',
    primary_key => ['empno'],
    columns => [
        sql_column(name => 'empno'),
        sql_column(name => 'ename', unique => 1),
        sql_column(name => 'job'),
        sql_column(name => 'deptno'),
    ],
);

isa_ok($emp_entity, $class);
{
    my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');
    $entity_manager->add_entities($emp_entity);
}


SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 12)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    ); 


    xml_dataset_ok('init');
    $emp_entity->insert(empno => "5", ename => "emp5", deptno => "3", job => 'Manager');
    expected_xml_dataset_ok('insert');

    {    
        my @emps = $emp_entity->find(undef, deptno => 3);
        my %result = (map  {($_->{the_rowid}  => $_) } @emps);
        my %exp_result = (
            3 => {the_rowid => 3, deptno => 3, empno => 3, ename => 'emp3', job => undef},
            5 => {the_rowid => 5, deptno => 3, empno => 5, ename => 'emp5', job => 'Manager'},
            1 => {the_rowid => 1, deptno => 3, empno => 1, ename => 'emp1', job => undef},
        );
        
        is_deeply(\%result, \%exp_result, 'should have emp records');
    }


    {    
        my @emps = $emp_entity->lock(undef, deptno => 3);
        my %result = (map  {($_->{the_rowid}  => $_) } @emps);
        my %exp_result = (
            3 => {the_rowid => 3, deptno => 3, empno => 3, ename => 'emp3', job => undef},
            5 => {the_rowid => 5, deptno => 3, empno => 5, ename => 'emp5', job => 'Manager'},
            1 => {the_rowid => 1, deptno => 3, empno => 1, ename => 'emp1', job => undef},
        );
        
        is_deeply(\%result, \%exp_result, 'should lock emp records');
    }


    ok(! $emp_entity->has_primary_key_values({job =>1}), 'should not have pk values');
    ok($emp_entity->has_primary_key_values({empno =>1}), 'should have pk values');
    
    my $result = $emp_entity->retrive_primary_key_values({ename => 'emp2'});
    is($result->{empno}, 2, 'should fetch pk values');
    
    
    eval {$emp_entity->primary_key_values({},1 ) };
    like($@, qr{primary key values }, 'should catch pk exception');
    $result = $emp_entity->primary_key_values({ename => 'emp4'}, 1);
    is($result->{empno}, 4,'should fetch pk values');

    xml_dataset_ok('init');
    $emp_entity->update({ename => "EMP4"}, {empno => '4'});
    expected_xml_dataset_ok('update');
    
    $emp_entity->delete(ename => 'emp2');
    expected_xml_dataset_ok('delete');
}