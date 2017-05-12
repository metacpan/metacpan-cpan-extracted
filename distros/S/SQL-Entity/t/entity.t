use strict;
use warnings;

use Test::More tests => 30;
use SQL::Entity::Column;

BEGIN {
    use_ok('SQL::Entity::Relationship', ':all');
    use_ok('SQL::Entity', ':all');
    use_ok('SQL::Entity::Table');
}


my $dept = SQL::Entity->new(
    name        => 'dept',
    primary_key => ['deptno'],
    alias       => 'd',
    columns     => [
        sql_column(name => 'deptno'),
        sql_column(name => 'dname')
    ],
);


my $entity = SQL::Entity->new(
    name                  => 'emp',
    primary_key		  => ['empno'],
    unique_expression     => 'rowid',
    columns               => [
        sql_column(name => 'ename', unique => 1),
        sql_column(name => 'empno'),
        sql_column(name => 'deptno')
    ],
);



isa_ok($entity, 'SQL::Entity');
{
    isa_ok($entity, 'SQL::Entity');
    my $stmt = "SELECT emp.rowid AS the_rowid,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp";
    my ($query, $bind) = $entity->query;
    is($query, $stmt, 'should strigify Entity');
}


$entity->add_to_one_relationships(sql_relationship(
    target_entity => $dept,
    condition     => sql_cond($dept->column('deptno'), '=', $entity->column('deptno'))
));



$entity->add_subquery_columns($dept->column('dname'));


isa_ok($entity, 'SQL::Entity');
{
    isa_ok($entity, 'SQL::Entity');
    my $stmt = "SELECT emp.rowid AS the_rowid,
  (SELECT d.dname
FROM dept d
WHERE d.deptno = emp.deptno) AS dname,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp";
    my ($query, $bind) = $entity->query;
    is($query, $stmt, 'should strigify Entity');
}

{
    my $stmt = "SELECT emp.rowid AS the_rowid,
  d.dname,
  emp.deptno,
  emp.ename,
  emp.empno
FROM emp
JOIN dept d ON (d.deptno = emp.deptno)
WHERE emp.empno > ? AND d.dname NOT LIKE ?";
    
    my ($sql, $bind_variables) = $entity->query(undef, 
      sql_cond('empno', '>', '20')->and(sql_cond('dname', 'NOT LIKE', 'HO%'))
    );
    is_deeply($bind_variables, ['20', 'HO%'], 'should have bind variables');
    is($sql, $stmt, 'should have query with where (case insensitive) clause');      
}



{
    my ($sql) = $entity->count;
    is($sql, "SELECT COUNT(*) AS count
FROM emp", 'should have count Entity');
}



{
    my ($sql, $bind_variables) = $entity->insert(
        dname  => 'hr',
        deptno => '10',
        ename  => 'adi',
        empno => '1',
    );
    is($sql, "INSERT INTO emp (deptno,empno,ename) VALUES (?,?,?)", "should have insert sql");
    is_deeply($bind_variables, ['10', '1', 'adi'], "should have bind variables");
}


{
    my ($sql, $bind_variables) = $entity->insert(
        dname  => 'hr',
        deptno => '10',
        ename  => 'adi',
        empno => '1',
    );
    is($sql, "INSERT INTO emp (deptno,empno,ename) VALUES (?,?,?)", "should have insert sql");
    is_deeply($bind_variables, ['10', '1', 'adi'], "should have bind variables");
}


{
    my ($sql, $bind_variables) = $entity->update(
        {dname  => 'hr',
        deptno => '10',
        ename  => 'adi',
        empno => '1',},
        {the_rowid => 'AAAMgzAAEAAAAAgAAB'},
    );

    is($sql, "UPDATE emp SET deptno = ?, empno = ?, ename = ? WHERE rowid = ?", "should have update sql");
    is_deeply($bind_variables, ['10', '1', 'adi', 'AAAMgzAAEAAAAAgAAB'], "should have bind variables");
}


{
    my ($sql, $bind_variables) = $entity->update(
        {dname  => 'hr',
        deptno => '10',
        empno => '1',
        ename  => 'adi',},
        {empno => '1'},
    );
    is($sql, "UPDATE emp SET deptno = ?, empno = ?, ename = ? WHERE empno = ?", "should have delete sql");
    is_deeply($bind_variables, ['10', '1', 'adi', '1'], "should have bind variables");
}


{
    my ($sql, $bind_variables) = $entity->delete(empno => '1');
    is($sql, "DELETE FROM emp WHERE empno = ?", "should have update sql");
    is_deeply($bind_variables, ['1'], "should have bind variables");
}

{
    my ($sql, $bind_variables) = $entity->delete(the_rowid => 'AAAMgzAAEAAAAAgAAB');
    is($sql, "DELETE FROM emp WHERE rowid = ?", "should have delete sql");
    is_deeply($bind_variables, ['AAAMgzAAEAAAAAgAAB'], "should have bind variables");
}


{
    my %condition_fields = $entity->unique_condition_values({ename => 'adi', deptno => 100});
    is_deeply(\%condition_fields, {ename => 'adi'}, 'should have unique_condition_values for unique column');
}


{
    my %condition_fields = $entity->unique_condition_values({empno => 1, ename => 'adi', deptno => 100});
    is_deeply(\%condition_fields, {empno => 1}, 'should have unique_condition_values for pk column');
}

{
    my %condition_fields = $entity->unique_condition_values({the_rowid => 'RRXX', empno => 1, ename => 'adi', deptno => 100});
    is_deeply(\%condition_fields, {rowid => 'RRXX'}, 'should have unique_condition_values for the_rowid');
}

{
    my %condition_fields = $entity->unique_condition_values({rowid => 'RRXX', empno => 1, ename => 'adi', deptno => 100});
    is_deeply(\%condition_fields, {rowid => 'RRXX'}, 'should have unique_condition_values for rowid');
}

{
    eval {$entity->unique_condition_values({deptno => 1}, 1);};
    ok($@, 'should catch unique_condition_values validation error');
    
}



{
    
    my $dept = SQL::Entity->new(
        name        => 'dept',
        primary_key => ['deptno'],
        alias       => 'd',
        columns     => [
            sql_column(name => 'deptno'),
            sql_column(name => 'dname')
        ],
        query_from  => "
        BEGIN
            :sql = my_sql_package_repository.get_sql('dept');
        
        END:
        ",
        query_from_helper => sub {
            my ($self) = @_;
            my $query_from = $self->query_from or die;
            #do some stuff
            'SELECT * FROM dept'
        }
    );
    my ($sql, $bind) = $dept->query;
    is($sql, 'SELECT d.deptno AS the_rowid,
  d.dname,
  d.deptno
FROM ( SELECT * FROM dept ) d', 'should have query from transformed');

}