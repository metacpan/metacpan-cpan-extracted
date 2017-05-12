%token ATOM

%%

sexp: '(' list ')'    { $_[2]; }
      ;

list: list element    { push(@{$_[1]}, $_[2]); $_[1] }|
                      { []; }
      ;

element: ATOM         { $_[1]; } |
         sexp         { $_[1]; }
         ;

%%

sub yylex
{
  my $parser = shift;

  $parser->YYData->{INPUT} or return('', undef);

  $parser->YYData->{INPUT} =~ s/^\s+//;
  $parser->YYData->{INPUT} =~ s/^#.*$//;

  for ($parser->YYData->{INPUT})
  {
    s/^([\(\)])// and return($1, undef);
    s/^([^\s\(\)]+)// and return('ATOM',$1);
    s/^(.)//s and return($1, $1);
  }
  return('', undef)
}

sub yyerror
{
  my ($msg, $s) = @_;
  die "$msg\n";
}
