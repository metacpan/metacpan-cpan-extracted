use MooseX::Declare;
use warnings;

class TSQL::AST::SQLDeclareCursorStatement extends TSQL::AST::SQLStatement {


has 'cursorName' => (
      is  => 'rw',
      isa => 'Str',
  );

}


1;