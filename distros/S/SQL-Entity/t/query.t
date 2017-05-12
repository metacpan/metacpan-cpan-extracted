use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
    use_ok('SQL::Query', ':all');
    use_ok('SQL::Entity', ':all');
    use_ok('SQL::Entity::Column', ':all');

}

{

    my $entity = SQL::Entity->new(
        name                  => 'emp',
        unique_expression     => 'rowid',
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
    );

    my $query = SQL::Query->new(entity => $entity);
    isa_ok($query, 'SQL::Query');
    
    my ($sql, $bind_variables) = $query->query();
    is($sql, "SELECT emp.*
FROM (
SELECT ROWNUM AS the_rownum,
  emp.rowid AS the_rowid,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp
WHERE ROWNUM < ?) emp
WHERE the_rownum >= ?", "should have Oracle navigation sql");
    is_deeply($bind_variables, [21, 1], "should have bind variables");
}


{
    my $entity = SQL::Entity->new(
        name                  => 'emp',
        unique_expression     => 'oid',
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
    );

    my $query = SQL::Query->new(entity => $entity, dialect => 'PostgreSQL');
    isa_ok($query, 'SQL::Query');
    
    my ($sql, $bind_variables) = $query->query();
    is($sql, "SELECT emp.*,nextval('rownum') AS the_rownum
FROM (
SELECT emp.oid AS the_rowid,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp) emp
LIMIT ? OFFSET ?", "should have PostgreSQL navigation sql");
}

{
    my $entity = SQL::Entity->new(
        name                  => 'emp',
        unique_expression     => 'oid',
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
    );

    my $query = SQL::Query->new(entity => $entity, dialect => 'MySQL');
    isa_ok($query, 'SQL::Query');
    
    my ($sql, $bind_variables) = $query->query();
    is($sql, 'SELECT emp.*,@rownum = @rownum + 1 AS the_rownum
FROM (
SELECT emp.oid AS the_rowid,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp) emp
LIMIT ? OFFSET ?', "should have MYSQL navigation sql");
}



{

    my $entity = SQL::Entity->new(
        name                  => 'emp',
        unique_expression     => 'rowid',
        columns               => [
            sql_column(name => 'ename'),
            sql_column(id   => 'match', expression => "CASE WHEN ename like '[% var1 %]' THEN 1 ELSE NULL END"),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
    );

    my $query = SQL::Query->new(entity => $entity);
    $query->set_sql_template_parameters({var1 => 'my param1'});
    
    my ($sql, $bind_variables) = $query->query();
    
    is($sql, "SELECT emp.*
FROM (
SELECT ROWNUM AS the_rownum,
  emp.rowid AS the_rowid,
  (CASE WHEN ename like 'my param1' THEN 1 ELSE NULL END) AS match,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp
WHERE ROWNUM < ?) emp
WHERE the_rownum >= ?", "should parse sql template parameters");

}

