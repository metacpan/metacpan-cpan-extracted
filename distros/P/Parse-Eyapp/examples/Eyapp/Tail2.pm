package Tail2;
use base qw(Exporter);
our @EXPORT = qw(_Error make_lexer Run);

sub _Error {
  my $parser = shift;
  my $yydata = $parser->YYData;

    exists $yydata->{ERRMSG}
  and do {
      print $yydata->{ERRMSG};
      delete $yydata->{ERRMSG};
      return;
  };
  my($token)=$parser->YYCurval;
  my($what)= $token->[0] ? "input: '$token->[0]'" : "end of input";
  my @expected = $parser->YYExpect();
  local $" = ', ';
  print << "ERRMSG";

Syntax error near $what (lin num $token->[1]). 
Expected one of these terminals: @expected
ERRMSG
}

sub make_lexer {
  my $input = shift;

  return sub {
      my($parser)=shift;

      for ($$input) {
          s/^\s+//;
          s/^([0-9]+(?:\.[0-9]+)?)//
                  and return('NUM',$1);
          s/^while//
                  and return('while', 'while');
          s/^([A-Za-z][A-Za-z0-9_]*)//
                  and return('VAR',$1);
          s/^(.)//s
                  and return($1,$1);
          return('',undef);
      }
      return('',undef);
  }
}

sub Run {
    my($self)=shift;
    my $input = shift or die "No input given\n";

    return $self->YYParse( 
      yylex => make_lexer($input), 
      yyerror => \&_Error,
      #yydebug =>0x1F
    );
}

1;
