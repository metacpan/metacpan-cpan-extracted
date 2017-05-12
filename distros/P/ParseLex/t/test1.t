#!/usr/local/bin/perl

BEGIN { push(@INC, './t') }
use W;
print W->new()->test('test1', "examples/tokenizer.pl", *DATA);

__END__
Tokenization of DATA:
Record number: 1
Type: INTEGER	Content:->1<-
Record number: 1
Type: ADDOP	Content:->+<-
Record number: 1
Type: INTEGER	Content:->2<-
Record number: 1
Type: ADDOP	Content:->-<-
Record number: 1
Type: INTEGER	Content:->5<-
Record number: 1
Type: NEWLINE	Content:->
<-
Record number: 3
Type: STRING	Content:->"This is a multiline
string with an embedded "" in it"<-
Record number: 3
Type: NEWLINE	Content:->
<-
Version X.XX
Trace is ON in class Parse::Lex
[main::lexer|Parse::Lex] Token read (INTEGER, [1-9][0-9]*): 1
[main::lexer|Parse::Lex] Token read (ADDOP, [-+]): +
[main::lexer|Parse::Lex] Token read (INTEGER, [1-9][0-9]*): 2
[main::lexer|Parse::Lex] Token read (ADDOP, [-+]): -
[main::lexer|Parse::Lex] Token read (INTEGER, [1-9][0-9]*): 5
[main::lexer|Parse::Lex] Token read (NEWLINE, \n): 

[main::lexer|Parse::Lex] Token read (STRING, \"(?:[^\"]+|\"\")*\"): "This is a multiline
string with an embedded "" in it"
[main::lexer|Parse::Lex] Token read (NEWLINE, \n): 

[main::lexer|Parse::Lex] Token read (ERROR, .*): this is an invalid string with a "" in it"
can't analyze: "this is an invalid string with a "" in it""
