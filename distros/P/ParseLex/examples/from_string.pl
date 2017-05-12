#!/usr/local/bin/perl
use lib '../lib';

use Parse::Lex;
use constant TRACE => 0;
$lexer = Parse::Lex->new (
			  qw(
			     ADDOP [-+]
			     INTEGER \d+
			    ));
$lexer->trace if TRACE;
my $expression = '1 + 2';
print join(' ', $lexer->analyze($expression)), "\n";
print $lexer->getCode()  if TRACE;
$lexer->from($expression);
$lexer->every (sub {
		 print $_[0]->name, "\t";
		 print $_[0]->text, "\n";
	       });
