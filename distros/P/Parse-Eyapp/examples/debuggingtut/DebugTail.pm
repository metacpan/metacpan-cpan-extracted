package DebugTail;
use strict;
use warnings;

sub lex {
  my $self = shift;

  for (${$self->input()}) {
    s{^(\s+)}{} and $self->tokenline($1 =~ tr{\n}{});
    
    return ($1,$1) if s/^(.)//;
  }
  return ('',undef);
}

1;
