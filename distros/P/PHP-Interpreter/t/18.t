use strict;
use Test::More tests => 6;

BEGIN {
    diag "Testing Passing interpreter globals";
    use_ok 'PHP::Interpreter' or die;
}

ok my $p = PHP::Interpreter->new(
  {
    'GET' => 
      {'name' => 'george',},
    'BRIC' => 
      {'special' => 'data',}
  }),
  "Create new PHP interpreter";

is $p->eval(q/return $_GET['name'];/), 'george', 'Checking $_GET';
is $p->eval(q/function foo(){ return $_GET['name'];} return foo();/), 'george', 'Checking $_GET is an autoglobal';
is $p->eval(q/return $_REQUEST['name'];/), 'george', 'Checking $_REQUEST population';
is $p->eval(q/return $BRIC['special'];/), 'data', 'Checking custom variable population';
