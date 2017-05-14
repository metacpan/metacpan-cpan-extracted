use MooseX::Declare;
use warnings;

class TSQL::AST::SQLUpdateStatement extends TSQL::AST::SQLStatement {

use TSQL::AST::SQLMultiPartName;
use TSQL::AST::SQLVariableName;

has 'updateTarget' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLMultiPartName | TSQL::AST::SQLVariableName ',
  );


}


1;