#!/usr/local/bin/perl -w

use strict;
require 5.005;
#BEGIN {  unshift @INC, "../lib"; }

use Parse::LexEvent;
print STDERR "Version $Parse::LexEvent::VERSION\n";

my @tokens = (
	      new Parse::Token::Simple(Name => 'ccomment', 
				       Handler => 'comment',
				       Regex => '//.*\n',
				      ),
	      new Parse::Token::Delimited(Name => 'comment',
					  Start => '/[*]', 
					  End => '[*]/'
					 ),
	      new Parse::Token::Quoted(Name => 'squotes', 
				       Handler => 'string',
				       Quote => qq!\'!, 
				      ),
	      new Parse::Token::Quoted(Name => 'dquotes', 
				       Handler => 'string',
				       Escape => '\\',
				       Quote => qq!\"!,	
				      ),
	      new Parse::Token::Simple(Name => 'remainder', 
				       Regex => '[^/\'\"]+', 
				       ReadMore => 1)
	    );

sub string {
  print $_[0]->name, ": $_[1]\n";
}
sub comment {
  print $_[0]->name, ": $_[1]\n";
}
sub remainder {
  print $_[0]->name, ": $_[1]\n";
}
#select STDERR;
my $lexer = Parse::LexEvent->new(@tokens);
$lexer->from(\*DATA);
$lexer->parse();

__END__
/*
  A C comment 
*/
// A C++ comment
var d = "string in \"double\" quotes";
var s = 'string in ''single'' quotes';
var x = 1;
var y = 2;
