#!/usr/local/bin/perl

require 5.004; 
BEGIN {  unshift @INC, "../lib"; }
use Parse::Lex;

$lexer = Parse::Lex->new(qw(
			    ADDOP [-+]
			    INTEGER \d+
			    NEWLINE \n
			   ));

$lexer->from(\*DATA);		#or $lexer->from(*DATA);
$lexer->every (sub { 
		 my $self = shift;
		 print $self->name, "\t";
		 print $self->text, "\n";
	       });

__END__
1+2+3+4+5+6+6+7+7+7-76
0+0+0+0+0+0+0+0+0+0+0+
1+2+3+4+5+6+6+7+7+7-76
