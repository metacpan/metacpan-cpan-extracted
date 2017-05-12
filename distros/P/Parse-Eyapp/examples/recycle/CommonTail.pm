package CommonTail;
use strict;
use warnings;
use base 'Parse::Eyapp::Driver';

#__PACKAGE__->error(sub { die 'Package CommonTail overwrites default error' });
__PACKAGE__->lexer(\&Lexer);
sub Lexer {
  my($parser)=shift;

  for (${$parser->input}) {
    s/^\s+//;

    s/^([0-9]+(?:\.[0-9]+)?)//   and return('NUM',$1);
    s/^([A-Za-z][A-Za-z0-9_]*)// and return('VAR',$1);
    s/^(.)//s                    and return($1,$1);

    return('',undef);
  }
}

1;
