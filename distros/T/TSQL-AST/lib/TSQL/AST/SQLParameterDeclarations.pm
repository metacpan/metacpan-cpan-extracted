use MooseX::Declare;
use warnings;

class TSQL::AST::SQLParameterDeclarations extends TSQL::AST::SQLFragment {

use TSQL::AST::SQLParameterDeclaration;


has 'parameterDeclarations' => (
      is  => 'rw',
      isa => 'ArrayRef[TSQL::AST::SQLParameterDeclaration]',
  );


}


1;