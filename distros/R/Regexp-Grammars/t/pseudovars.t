use strict;
use warnings;


# ABSTRACT: Test Regexp::Grammars exports package symbols.

use Regexp::Grammars;
use Test::More;

sub has_var {
  my  ($varname) = @_;
  local $@;
  eval <<"EOF";
  my \$grammar = qr{<MATCH=(?{ $varname })>}
EOF
  note $@ if $@;
  return !$@;
}

for my $varname (qw( $CAPTURE $CONTEXT $DEBUG $INDEX $MATCH %ARG %MATCH )) {
  ok( has_var($varname), "Has $varname" );
}

done_testing;

