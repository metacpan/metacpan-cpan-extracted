use MooseX::Declare;
use warnings;

class TSQL::AST::SQLConditionalExpression extends TSQL::AST::SQLFragment {

#use TSQL::AST::SQLFragment ;

has 'expression' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLFragment',
  );


}


1;