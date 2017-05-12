use strict;
use warnings;

use Test::More tests => 9;
use SQL::Entity::Column;

BEGIN {
    use_ok('SQL::Entity::Column', ':all');
    use_ok('SQL::Entity::Condition', ':all');
    use_ok('SQL::Entity');
    use_ok('SQL::Query');
    use_ok('SQL::Entity::Index', ':all');
}


    my $entity = SQL::Entity->new(
        name                  => 'emp',
        primary_key		  => ['empno'],
        unique_expression     => 'rowid',
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
        indexes => [
            sql_index(name => 'idx_emp_empno', columns => ['empno']),
            sql_index(name => 'idx_emp_ename', columns => ['ename'], hint => 'INDEX_ASC(emp idx_emp_ename)'),
        ],
        order_index => 'idx_emp_ename'
    );

{
    my ($sql, $bind_variables) = $entity->query();
    is($sql,"SELECT emp.rowid AS the_rowid,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp ORDER BY ename", "should have order by clause");
}
    
    my $query = SQL::Query->new(entity => $entity);
    isa_ok($query, 'SQL::Query');
    
    {
    my ($sql, $bind_variables) = $query->query();
    is($sql, "SELECT emp.*
FROM (
SELECT /*+ INDEX_ASC(emp idx_emp_ename) */ ROWNUM AS the_rownum,
  emp.rowid AS the_rowid,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp
WHERE ROWNUM < ?) emp
WHERE the_rownum >= ?", "should have hint");
    }
    
    $query->order_index('idx_emp_empno');
    my ($sql, $bind_variables) = $query->query();
    is($sql, "SELECT emp.*
FROM (
SELECT ROWNUM AS the_rownum,
  emp.rowid AS the_rowid,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp
WHERE ROWNUM < ? ORDER BY empno) emp
WHERE the_rownum >= ?", "should have order by - missing hint");

 