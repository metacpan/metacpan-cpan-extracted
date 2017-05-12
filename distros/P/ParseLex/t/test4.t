#!/usr/local/bin/perl

BEGIN { push(@INC, './t') }
use W;
print W->new()->test('test4', "examples/ctokenizer.pl", *DATA);

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
Trace is ON in class Parse::CLex
[main::lexer|Parse::CLex] Token read (INTEGER, [1-9][0-9]*): 1
[main::lexer|Parse::CLex] Token read (ADDOP, [-+]): +
[main::lexer|Parse::CLex] Token read (INTEGER, [1-9][0-9]*): 2
[main::lexer|Parse::CLex] Token read (ADDOP, [-+]): -
[main::lexer|Parse::CLex] Token read (INTEGER, [1-9][0-9]*): 5
[main::lexer|Parse::CLex] Token read (NEWLINE, \n): 

[main::lexer|Parse::CLex] Token read (STRING, \"(?:[^\"]+|\"\")*\"): "This is a multiline
string with an embedded "" in it"
[main::lexer|Parse::CLex] Token read (NEWLINE, \n): 

[main::lexer|Parse::CLex] Token read (ERROR, .*): this is an invalid string with a "" in it"
can't analyze: "this is an invalid string with a "" in it"" at examples/ctokenizer.pl line 17, <DATA> line 4.
