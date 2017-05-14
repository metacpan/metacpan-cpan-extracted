use MooseX::Declare;
use warnings;

class TSQL::AST::SQLParametersDeclaration extends TSQL::AST::SQLFragment {

#use TSQL::AST::SQLIdentifier;
use TSQL::AST::SQLVariableName;
use TSQL::AST::SQLDataType;

has 'parameterName' => (
      is  => 'rw',
#      isa => 'TSQL::AST::SQLIdentifier',
      isa => 'TSQL::AST::SQLVariableName',
  );


has 'parameterType' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLDataType',
  );


}


1;