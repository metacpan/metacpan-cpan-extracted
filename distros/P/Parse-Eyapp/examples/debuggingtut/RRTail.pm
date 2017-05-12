package RRTail;
use strict;
use warnings;
use base q{DebugTail};

__PACKAGE__->lexer( sub {
    my $self = shift;
    
    for (${$self->input()}) {
      s{^(\s*)}{};

      return ('',undef) unless $_;

      return ('NUM',$1) if s/^(\d+)//;
      return ('ID',$1)  if s/^([a-zA-Z_]\w*)//;
    }
    return ('',undef);
  }
);


1;
