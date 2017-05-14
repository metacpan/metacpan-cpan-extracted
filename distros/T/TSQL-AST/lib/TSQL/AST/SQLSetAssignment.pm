use MooseX::Declare;
use warnings;

class TSQL::AST::SQLSetAssignment extends TSQL::AST::SQLStatement {

use TSQL::AST::SQLIdentifier;

has 'targetVariable' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLIdentifier',
  );


}


1;