use MooseX::Declare;
use warnings;

class TSQL::AST::SQLVariableDeclaration extends TSQL::AST::SQLFragment {

#use TSQL::AST::SQLIdentifier;
use TSQL::AST::SQLVariableName;
use TSQL::AST::SQLDataType;

has 'variableName' => (
      is  => 'rw',
#      isa => 'TSQL::AST::SQLIdentifier',
      isa => 'TSQL::AST::SQLVariableName',
  );


has 'variableType' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLDataType',
  );

}


1;