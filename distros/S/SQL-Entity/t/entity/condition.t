use strict;
use warnings;

use Test::More tests => 16;

BEGIN {
  use_ok('SQL::Entity::Condition',':all');
};

{
	my $cond = sql_and( 
	  sql_cond('a', '=', 1),
	  sql_cond('b', '>', 1),
	  sql_cond('c', '<', 1),
  );	  
  is($cond->as_string,"a = 1 AND b > 1 AND c < 1",'simple AND condition');
}

  {
	my $cond = sql_cond('a', '=', 1)->and(sql_cond('b', '>', 1));
    is($cond->as_string,"a = 1 AND b > 1",'simple AND condition');
  }


{
	my $cond = sql_or( 
	  sql_cond('a', '=', 1),
	  sql_cond('b', '>', 1),
	  sql_cond('c', '<', 1),
      );	  
  is($cond->as_string,"a = 1 OR b > 1 OR c < 1",'simple OR condition');
}

{
		my $cond = sql_cond('a', '=', 1);
		isa_ok($cond,    'SQL::Entity::Condition');
		is($cond->as_string, "a = 1", 'simple condition');
		$cond->and( sql_cond('b', '=', 1) );
		is($cond->as_string, "a = 1 AND b = 1", 'composite AND condition');
		my $cond_or = $cond->or( sql_cond('c', 'LIKE', 1));
		is($cond_or->as_string, "(a = 1 AND b = 1) OR c LIKE 1", 'composite AND and OR condition');
}

{
		my $cond = sql_cond('a', '=', 1);
		$cond->or( sql_cond('b', '=', 1) );
		is($cond->as_string, "a = 1 OR b = 1", 'composite OR condition');
		my $cond_and = $cond->and( sql_cond('c', 'LIKE', 1));
		is($cond_and->as_string, "(a = 1 OR b = 1) AND c LIKE 1", 'composite OR and AND condition');
}

{
  my $cond = SQL::Entity::Condition->struct_to_condition(a => 1, b => 3);
  is($cond->as_string, "a = 1 AND b = 3", 'should have condition from data structure');
}


{
  my $cond = SQL::Entity::Condition->struct_to_condition(a => 1, b => [1,3]);
  is($cond->as_string, "a = 1 AND b IN (1,3)", 'should have condition from data structure');
}

{
  my $cond = SQL::Entity::Condition->struct_to_condition(a => 1, b => {operator => '!=', operand => 3});
  is($cond->as_string, "a = 1 AND b != 3", 'should have condition from data structure');
}


{
  my $cond = SQL::Entity::Condition->struct_to_condition(a => 1, b => {operator => 'LIKE', operand => "'A%'", relation => 'OR'});
  is($cond->as_string, "a = 1 OR b LIKE 'A%'", 'should have condition from data structure');
}

{
    my $cond = sql_cond('a', 'IN', [1,2,3]);
    my $bind_variables = [];
    my $sql = $cond->as_string(undef, $bind_variables);
    is($sql, "a IN (?,?,?)", ' should have in condition');
    is_deeply($bind_variables, [1,2,3], 'should have bind variables');
}