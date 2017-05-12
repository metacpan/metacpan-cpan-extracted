#!/usr/local/bin/perl 

require 5.004; 
#BEGIN {  unshift @INC, "../lib"; }

$^W = 0;
use Parse::Lex;
print STDERR "Version $Parse::ALex::VERSION\n";

@token = (
	  qw(
	     ADDOP    [-+]
	     LEFTP    [\(]
	     RIGHTP   [\)]
	     INTEGER  [1-9][0-9]*
	     NEWLINE  \n
	    ),
	  qw(STRING),   [qw(" (?:[^"]+|"")* ")],
	  qw(ERROR  .*), sub {
	    die qq!can\'t analyze: "$_[1]"\n!;
	  }
	 );

Parse::Lex->trace;
$lexer = Parse::Lex->new(@token);

$lexer->from(\*DATA);
print "Tokenization of DATA:\n";

TOKEN:while (1) {
  $token = $lexer->next;
  if (not $lexer->eoi) {
    print "Record number: ", $lexer->line, "\n";
    print "Type: ", $token->name, "\t";
    print "Content:->", $token->text, "<-\n";
  } else {
    last TOKEN;
  }
}

__END__
1+2-5
"This is a multiline
string with an embedded "" in it"
this is an invalid string with a "" in it"


