#!/usr/local/bin/perl -w
require 5.000;

use lib "../lib";
use Parse::CLex;

@token = qw(
	    ADDOP    [-+]
	    INTEGER  [1-9][0-9]*
	   );

$lexer = Parse::CLex->new(@token);
$lexer->from(\*DATA);

$content = $INTEGER->next;
if ($INTEGER->status) {
  print "$content\n";
}
$content = $ADDOP->next;
if ($ADDOP->status) {
  print "$content\n";
}
if ($INTEGER->isnext(\$content)) {
  print "$content\n";
}

__END__
1+2



