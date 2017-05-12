package TailModule;

sub _Error {
  my($token)=$_[0]->YYCurval;
  my($what)= $token ? "input: '$token'" : "end of input";
  my @expected = $_[0]->YYExpect();

  local $" = ', ';
  die "Syntax error near $what. Expected one of these tokens: @expected\n";
}

my $x;

sub _Lexer {
  my($parser)=shift;

  for ($x) {
    s/^\s+//;
    $_ eq '' and return('',undef);

    s/^([0-9]+(?:\.[0-9]+)?)//   and return('NUM',$1);
    s/^([A-Za-z][A-Za-z0-9_]*)// and return('VAR',$1);
    s/^(.)//s                    and return($1,$1);
  }
}

sub Run {
  my($self)=shift;
  print "Write an expression: "; 
  $x = <>;
  $self->YYParse( yylex => \&_Lexer, 
    yyerror => \&_Error,
    #yydebug => 0xFF
  );
}
sub chum {
  print "chum\n"
}

1;

