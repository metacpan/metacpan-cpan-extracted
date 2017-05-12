require 5.000;

use Parse::Lex;
print STDERR "Version $Parse::Lex::VERSION\n";
@token = qw(
	    ADDOP    [-+]
	    INTEGER  [1-9][0-9]*
	   );

$lexer = Parse::Lex->new(@token);
$lexer->from(\*DATA);

Parse::Token->trace();
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



