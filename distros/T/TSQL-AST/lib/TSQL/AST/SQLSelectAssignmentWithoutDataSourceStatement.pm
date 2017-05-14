use MooseX::Declare;
use warnings;

class TSQL::AST::SQLSelectAssignmentWithoutDataSourceStatement extends TSQL::AST::SQLStatement {

use TSQL::AST::SQLIdentifier;

has 'targetVariables' => (
      is  => 'rw',
      isa => 'ArrayRef[TSQL::AST::SQLIdentifier]',
  );

}


1;