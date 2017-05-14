use MooseX::Declare;
use warnings;

class TSQL::AST::SQLInsertStatement extends TSQL::AST::SQLStatement {

use TSQL::AST::SQLMultiPartName;
use TSQL::AST::SQLVariableName;

has 'insertTarget' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLMultiPartName | TSQL::AST::SQLVariableName ',
  );



}


1;