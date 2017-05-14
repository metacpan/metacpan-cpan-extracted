use MooseX::Declare;
use warnings;

class TSQL::AST::SQLMergeStatement extends TSQL::AST::SQLStatement {

use TSQL::AST::SQLMultiPartName;
use TSQL::AST::SQLVariableName;

has 'mergeTarget' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLMultiPartName | TSQL::AST::SQLVariableName ',
  );


}


1;