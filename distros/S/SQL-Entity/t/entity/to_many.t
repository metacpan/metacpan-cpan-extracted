use strict;
use warnings;

use Test::More tests => 8;
use SQL::Entity ':all';

my $class;

BEGIN {
    $class = 'SQL::Entity::Relationship';
    use_ok($class, ':all');
}

my $dept = SQL::Entity->new(
    name    => 'dept',
    alias   => 'd',
    primary_key => ['deptno'],
    columns => [
        sql_column(name => 'deptno'),
        sql_column(name => 'dname')
    ],
);


my $emp = SQL::Entity->new(
    name                  => 'emp',
    primary_key		  => ['empno'],
    unique_expression     => 'rowid',
    columns               => [
        sql_column(name => 'ename'),
        sql_column(name => 'empno'),
        sql_column(name => 'deptno')
    ],
);

my $dummy = SQL::Entity->new(
    name    => 'dummy',
    alias   => 'd1',
    primary_key => ['dummyno'],
    columns => [
        sql_column(name => 'dname')
    ],
);


my $relationship = $class->new(target_entity => $emp, join_columns => ['deptno']);
isa_ok($relationship, $class);
$dept->add_to_many_relationships($relationship);

my $fake_relation = sql_relationship(target_entity => $dept, join_columns => ['deptnox']);
$dept->add_to_many_relationships($fake_relation);

my $dummy_rel = $class->new(target_entity => $dept, join_columns => ['deptno']);
$dummy->add_to_many_relationships($dummy_rel);

my $to_one_relation = $emp->to_one_relationship($dept->id);
ok($to_one_relation, 'should have reflective to one relation');
is_deeply([$to_one_relation->join_columns], ['deptno'], 'should have columns');
is($to_one_relation->target_entity, $dept, 'should have target entity');
   

my ($sql, $bind_variable) = $dept->relationship_query('emp', deptno => '10');
my $exp_sql = "SELECT emp.rowid AS the_rowid,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp
WHERE EXISTS (SELECT 1 FROM dept d WHERE d.deptno = emp.deptno AND d.deptno = ?)";
is($sql, $exp_sql, "should strigify");


eval {$fake_relation->join_columns_values($dept)};
like($@, qr{unknown foreign key column: deptnox on dept}, 'should catch unknown foreign key column error');

eval {$dummy_rel->join_columns_values($dummy)};
like($@, qr{unknown primary key column}, 'should catch unknown primary key column error');
