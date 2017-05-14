use MooseX::Declare;
use warnings;

class TSQL::AST::SQLCreateOrAlterFunction extends TSQL::AST::SQLFragment {

use TSQL::AST::SQLStatement;
use TSQL::AST::SQLMultiPartName;
use TSQL::AST::SQLParameterDeclarations;

has 'name' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLMultiPartName',
  );

has 'parameters' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLParameterDeclarations',
  );


has 'body' => (
      is  => 'rw',
      isa => 'ArrayRef[TSQL::AST::SQLStatement]',
  );


}


1;