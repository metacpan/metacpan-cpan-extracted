use strict;
use warnings;

use Test::More tests => 7;
use SQL::Entity::Column;

BEGIN {
    use_ok('SQL::Entity::Column', ':all');
    use_ok('SQL::Entity::Table');
}

my $table = SQL::Entity::Table->new(name => 'emp');
isa_ok($table, 'SQL::Entity::Table');
my $empno = sql_column(name => 'empno');
$table->add_columns($empno);

{
    my ($sql) = $table->query;
    is($sql, "SELECT emp.empno
FROM emp", 'should stringify table Entity');
}

{
    my ($sql) = $table->count;
    is($sql, "SELECT COUNT(*) AS count
FROM emp", 'should have count Entity');
}

my $deptno = sql_column(name => 'deptno', updatable => 0);
$table->add_columns($deptno);
                    
my $ename = sql_column(name => 'ename', insertable => 0);                    
$table->add_columns($ename);

ok((grep { $empno eq $_ }  $table->insertable_columns) && (grep { $deptno eq $_ }  $table->insertable_columns), 'should retrieve insertable_columns');
ok((grep { $empno eq $_ }  $table->updatable_columns) && (grep { $ename eq $_ }  $table->updatable_columns), 'should retrieve updatable_columns');
