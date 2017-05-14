use MooseX::Declare;
use warnings;

class TSQL::AST::SQLExecuteStatement extends TSQL::AST::SQLStatement {

use TSQL::AST::SQLMultiPartName;
use TSQL::AST::SQLParameterUsage;


has 'procedureName' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLMultiPartName',
  );


has 'parameterUsage' => (
      is  => 'rw',
      isa => 'ArrayRef[TSQL::AST::SQLParameterUsage]',
  );

}


1;