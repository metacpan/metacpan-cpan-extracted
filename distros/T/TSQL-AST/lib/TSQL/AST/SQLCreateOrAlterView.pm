use MooseX::Declare;
use warnings;

class TSQL::AST::SQLCreateOrAlterView extends TSQL::AST::SQLFragment {

use TSQL::AST::SQLStatement;
#use TSQL::AST::SQLMultiPartName;
#use TSQL::AST::SQLParametersDeclaration;
#use TSQL::AST::SQLQuery;

has 'name' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLMultiPartName',
  );


has 'body' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLQuery',
  );


}


1;