#!/usr/local/bin/perl -w

use strict;
require 5.000;
BEGIN {  unshift @INC, "../lib"; }

use Parse::LexEvent;
print STDERR "Version $Parse::LexEvent::VERSION\n";

my @tokens = Parse::Token->factory([
				    Type => 'Simple',
				    Name => 'ccomment', 
				    Handler => 'comment',
				    Regex => '//.*\n',
				    # 
				    Type => 'Delimited',
				    Name => 'comment',
				    Start => '/[*]', 
				    End => '[*]/',
				    # 
				    Type => 'Quoted',
				    Name => 'squotes', 
				    Handler => 'string',
				    Quote => qq!\'!, 
				    # 
				    Type => 'Quoted',
				    Name => 'dquotes', 
				    Handler => 'string',
				    Escape => '\\',
				    Quote => qq!\"!,	
				    # 
				    Type => 'Simple',
				    Name => 'remainder', 
				    Regex => '[^/\'\"]+', 
				    ReadMore => 1
				   ]);

sub string {
  print $_[0]->name, ": $_[1]\n";
}
sub comment {
  print $_[0]->name, ": $_[1]\n";
}
sub remainder {
  print $_[0]->name, ": $_[1]\n";
}

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

