#!perl

# $Id: Lexer.t,v 1.4 2013/07/27 00:34:39 Paulo Exp $

use 5.010;
use strict;
use warnings;

use Test::More;
use File::Slurp;
use Data::Dump 'dump';

use_ok 'Parse::FSM::Lexer';

#------------------------------------------------------------------------------
# Globals
my($lex, $file, $incfile);
my @TEMP; END { unlink @TEMP };
my $warn; $SIG{__WARN__} = sub {$warn = shift};

my @input = map {"$_\n"} 1..4;
my $input = join '', @input;

#------------------------------------------------------------------------------
sub tmpfile {
	my $file = "tmp~".scalar(@TEMP)."~";
	if (@_) {
		write_file($file, @_);
	}
	else {
		unlink $file; 
	}
	push @TEMP, $file;
	return $file;
}

#------------------------------------------------------------------------------
sub t_get {
	my($file, $line_nr, @tokens) = @_;
	my $id = "[line ".(caller)[2]."]";
	
	$file =~ s/\\/\//g if defined $file;
	
	if (@tokens) {
		while (my($type, $value) = splice(@tokens, 0, 2)) {
			is_deeply 	$lex->get_token, [$type, $value],
						"$id [".dump($type)." => ".dump($value)."]";
	
			my $lex_file = $lex->file;
			$lex_file =~ s/\\/\//g if defined $lex_file;
			
			is 			$lex_file, $file,			
						"$id file ".dump($file);
						
			is			$lex->line_nr, $line_nr,	
						"$id line_nr ".dump($line_nr);
		}
	}
	else {
		is	$lex->get_token, undef, "$id EOF";
		is	$lex->get_token, undef, "$id EOF";
	}
}

#------------------------------------------------------------------------------
sub t_error { 
	my($error_msg, $expected_message) = @_;
	my $line_nr = (caller)[2];
	my $test_name = "[line $line_nr]";

	(my $expected_error   = $expected_message) =~ s/XXX/Error/;
	(my $expected_warning = $expected_message) =~ s/XXX/Warning/;
	
	eval {	$lex->error($error_msg) };
	is		$@, $expected_error, "$test_name die()";
	
			$warn = "";
			$lex->warning($error_msg);
	is 		$warn, $expected_warning, "$test_name warning()";
	$warn = undef;
}

#------------------------------------------------------------------------------
# no input
$lex = new_ok('Parse::FSM::Lexer');
t_get();

#------------------------------------------------------------------------------
# no input file
$file = tmpfile();
eval { Parse::FSM::Lexer->new($file) };
is $@, "Error : unable to open input file '$file'\n";

$incfile = tmpfile();
$file = tmpfile("#include '$incfile'\n");
eval { Parse::FSM::Lexer->new($file)->get_token };
is $@, "Error at file '$file', line 1 : unable to open input file '$incfile'\n";

#------------------------------------------------------------------------------
# empty input file
$file = tmpfile("");
$lex = new_ok('Parse::FSM::Lexer', [$file]);
t_get();

#------------------------------------------------------------------------------
# file with Data
$file = tmpfile($input);
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_file($file);
t_get($file, 1, NUM => 1);
t_get($file, 2, NUM => 2);
t_get($file, 3, NUM => 3);
t_get($file, 4, NUM => 4);
t_get();

#------------------------------------------------------------------------------
# file with Data, pass on constructor
$file = tmpfile($input);
$lex = new_ok('Parse::FSM::Lexer', [$file]);
t_get($file, 1, NUM => 1);
t_get($file, 2, NUM => 2);
t_get($file, 3, NUM => 3);
t_get($file, 4, NUM => 4);
t_get();

#------------------------------------------------------------------------------
# pass two files to constructor, read in correct order
$lex = new_ok('Parse::FSM::Lexer', ['t/Data/f01.asm', 't/Data/f02.asm']);

t_get('t/Data/f01.asm',	1, NAME => "hello");
t_get('t/Data/f02.asm',	1, NAME => "world");
t_get();

#------------------------------------------------------------------------------
# one file to constructor, other included
$lex = new_ok('Parse::FSM::Lexer', ['t/Data/f02.asm']);
$lex->from_file('t/Data/f01.asm');

t_get('t/Data/f01.asm',	1, NAME => "hello");
t_get('t/Data/f02.asm',	1, NAME => "world");
t_get();

#------------------------------------------------------------------------------
# input from empty list
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list();
t_get();

#------------------------------------------------------------------------------
# input from list, test handling of \r \t \f
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list(1,2,"\t3\r\f\r\n4 \r\n\n\n5");
t_get(undef, 1, NUM => 1, NUM => 2, NUM => 3);
t_get(undef, 2, NUM => 4);
t_get(undef, 5, NUM => 5);
t_get();

#------------------------------------------------------------------------------
# input from list
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list(@input);
t_get(undef, 1, NUM => 1);
t_get(undef, 2, NUM => 2);
t_get(undef, 3, NUM => 3);
t_get(undef, 4, NUM => 4);
t_get();

#------------------------------------------------------------------------------
# input from one big string
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list($input);
t_get(undef, 1, NUM => 1);
t_get(undef, 2, NUM => 2);
t_get(undef, 3, NUM => 3);
t_get(undef, 4, NUM => 4);
t_get();

#------------------------------------------------------------------------------
# input from iterator
my @input_copy = @input;
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list(sub {shift @input_copy});
t_get(undef, 1, NUM => 1);
t_get(undef, 2, NUM => 2);
t_get(undef, 3, NUM => 3);
t_get(undef, 4, NUM => 4);
t_get();

#------------------------------------------------------------------------------
# test #line
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list(
'	1
	2
	3
#line 1 file.asm
	4
	5
#line 3 "f2.asm"
	6
	7
#line 8 "z.asm"
	8
	9
#line 8 x.asm
	10
	11
#line 25 x.asm
	12
	13
#line 45 x.asm
	15
	16
');
t_get(undef, 		1, NUM => 1);
t_get(undef, 		2, NUM => 2);
t_get(undef, 		3, NUM => 3);

t_get("file.asm", 	1, NUM => 4);
t_get("file.asm", 	2, NUM => 5);

t_get("f2.asm", 	3, NUM => 6);
t_get("f2.asm", 	4, NUM => 7);

t_get("z.asm",	 	8, NUM => 8);
t_get("z.asm",	 	9, NUM => 9);

t_get("x.asm",	 	8, NUM => 10);
t_get("x.asm",	 	9, NUM => 11);

t_get("x.asm",	 	25, NUM => 12);
t_get("x.asm",	 	26, NUM => 13);

t_get("x.asm",	 	45, NUM => 15);
t_get("x.asm",	 	46, NUM => 16);

t_get();

#------------------------------------------------------------------------------
# #include as list
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list('#include "t/Data/f01.asm"', 
				"#include 't/Data/f02.asm'", 
				"#include  t/Data/f01.asm ",
				"#include <t/Data/f02.asm>",);

t_get('t/Data/f01.asm',	1, NAME => "hello");
t_get('t/Data/f02.asm',	1, NAME => "world");
t_get('t/Data/f01.asm',	1, NAME => "hello");
t_get('t/Data/f02.asm',	1, NAME => "world");
t_get();

#------------------------------------------------------------------------------
# #include error
$lex = new_ok('Parse::FSM::Lexer', ['t/Data/f03.asm']);
eval { $lex->get_token };

is $@, "Error at file 't/Data/f03.asm', line 1 : #include expects a file name\n", "wrong syntax";

#------------------------------------------------------------------------------
# #include from file
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_file('t/Data/f04.asm');
t_get('t/Data/f01.asm',	1, NAME => "hello");
t_get('t/Data/f02.asm',	1, NAME => "world");
t_get('t/Data/f01.asm',	1, NAME => "hello");
t_get('t/Data/f02.asm',	1, NAME => "world");
t_get();

#------------------------------------------------------------------------------
# #include from file
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list("#include 't/Data/include.z80'");

t_get('t/Data/include.z80', 1, NAME => "NOP");
t_get('t/Data/include.z80', 2, NAME => "NOP");
t_get();

#------------------------------------------------------------------------------
# #include from file
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list("#include 't/Data/include3.z80'");

t_get('t/Data/include3.z80', 1, NAME => "LD", NAME => "B", "," => ",", NUM => 1);
t_get('t/Data/include2.z80', 1,	NAME => "LD", NAME => "A", "," => ",", NUM => 1);

t_get('t/Data/include.z80', 1, NAME => "NOP");
t_get('t/Data/include.z80', 2, NAME => "NOP");

t_get('t/Data/include2.z80', 3,	NAME => "LD", NAME => "A", "," => ",", NUM => 3);

t_get('t/Data/include.z80', 1, NAME => "NOP");
t_get('t/Data/include.z80', 2, NAME => "NOP");

t_get('t/Data/include2.z80', 5,	NAME => "LD", NAME => "A", "," => ",", NUM => 5);

t_get('t/Data/include.z80', 1, NAME => "NOP");
t_get('t/Data/include.z80', 2, NAME => "NOP");

t_get('t/Data/include2.z80', 7,	NAME => "LD", NAME => "A", "," => ",", NUM => 7);

t_get('t/Data/include.z80', 1, NAME => "NOP");
t_get('t/Data/include.z80', 2, NAME => "NOP");

t_get('t/Data/include2.z80', 9,	NAME => "LD", NAME => "A", "," => ",", NUM => 9);

t_get('t/Data/include3.z80', 3, NAME => "LD", NAME => "B", "," => ",", NUM => 3);

t_get();

#------------------------------------------------------------------------------
# path_search
$lex = new_ok('Parse::FSM::Lexer');
is_deeply [$lex->path], [], "empty path";
$lex->add_path('t/Data');
is_deeply [$lex->path], ['t/Data'], "one in path";
$lex->add_path('t/Data/sub');
is_deeply [$lex->path], ['t/Data', 't/Data/sub'], "two in path";

is $lex->path_search('t/Data/f01.asm'), 't/Data/f01.asm', 
							"path search, file found before search";
is $lex->path_search('NO FILE'), 'NO FILE', 
							"path search, file not found";
like $lex->path_search('f01.asm'), qr{t[\\/]Data[\\/]f01.asm}, 
							"path search, file found in first dir";
like $lex->path_search('f11.asm'), qr{t[\\/]Data[\\/]sub[\\/]f11.asm}, 
							"path search, file found in second dir";

$lex->from_file('f06.asm');
t_get('t/Data/f01.asm',	1, NAME => "hello");
t_get('t/Data/f02.asm',	1, NAME => "world");
t_get();

#------------------------------------------------------------------------------
# recursive include
$lex = new_ok('Parse::FSM::Lexer', ['t/Data/f07.asm']);
eval { $lex->get_token };
is $@, "Error at file 't/Data/f08.asm', line 1 : #include loop\n",
			"#include loop";

#------------------------------------------------------------------------------
# error

$lex = new_ok('Parse::FSM::Lexer');

t_error(undef, "XXX\n");
t_error("test error", 	"XXX : test error\n");
t_error("test error\n", "XXX : test error\n");

$lex->line_nr(1);
t_error("test error",	"XXX at line 1 : test error\n");

$lex->file("f1.asm");
t_error("test error",	"XXX at file 'f1.asm', line 1 : test error\n");

$lex->line_nr(0);
t_error("test error",	"XXX at file 'f1.asm' : test error\n");

is $warn, undef, "no warnings";

#------------------------------------------------------------------------------
# comments
for my $prefix ("#", " #", " # ") {
	my $text = $prefix."undefined_directive\n";
	$lex = new_ok('Parse::FSM::Lexer', [], dump($text));
	$lex->from_list($text);
	t_get();
}

#------------------------------------------------------------------------------
# test handling of \r in Unix and Win systems
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list(" 1 \r 2 \r\n\r\n 3 \n 4");
t_get(undef, 1, NUM => 1, NUM => 2);
t_get(undef, 3, NUM => 3);
t_get(undef, 4, NUM => 4);
t_get();

#------------------------------------------------------------------------------
# tokens symbols
$lex = new_ok('Parse::FSM::Lexer');
$input = "<< >> == != >= <= < > = ! ( ) + - * / % , :"; 
diag "Reading $input";
$lex->from_list($input);
for (split(" ", $input)) {
	t_get(undef, 1, $_ => $_);
}
t_get();

#------------------------------------------------------------------------------
# tokens strings
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list(q{'' "" '"' "'" 'hello' "world"}, "\n",
				q{'clo;sed' "string" 'with''quote' "and""quote"}, "\n",
				q{'quote \\'' "quote \\""}, "\n");
t_get(undef, 1, STR => "", STR => "", STR => '"', STR => "'", 
				STR => "hello", STR => "world");
t_get(undef, 2, STR => "clo;sed", STR => "string", STR => "with", STR => "quote", 
				STR => "and", STR => "quote");
t_get(undef, 3, STR => 'quote \'', STR => "quote \"");
t_get();

#------------------------------------------------------------------------------
# tokens numbers
$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list("0 1 234 567 89");
t_get(undef, 1, NUM => 0, NUM => 1, NUM => 234, NUM => 567, NUM => 89);
t_get();

$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list("0xAF 0xaf 0x100 ");
t_get(undef, 1, NUM => 0xaf, NUM => 0xaf, NUM => 0x100);
t_get();

$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list("010 020 030 ");
t_get(undef, 1, NUM => 8, NUM => 16, NUM => 24);
t_get();

$lex = new_ok('Parse::FSM::Lexer');
$lex->from_list("0b01 0b10 0b010");
t_get(undef, 1, NUM => 0b01, NUM => 0b10, NUM => 0b10);
t_get();

#------------------------------------------------------------------------------
# lines ended in back-slash
{
	package MyLexer;
	use base 'Parse::FSM::Lexer';
	sub tokenizer {
		my($self, $rtext) = @_;
		our $LINE_NR; local $LINE_NR;
		
		$$rtext =~ m{\G
			(?:
				# number
				(?> ( \d+ ) \b 				(?{ [NUM => 0+$^N] }) )
				
				# name
			|	(?> ( [a-z_]\w* )			(?{ [NAME => $^N] }) )

				# backslash-newline sequence
			|	(?> \\ \n					(?{ undef }) )
				
				# newline
			|	(?> \n						(?{ ["\n" => "\n"] }) )
			
				# white space
			|	(?> (?&SP)+					(?{ undef }) )
			
				# others
			|	(?> ( . )					(?{ [$^N => $^N] }) )
			)
		
			(?(DEFINE)
				# horizontal blanks
				(?<SP>	[\t\f\r ] )
			)
		}gcxmi or die 'not reached';
		return $^R;
	}
}

$lex = new_ok('Parse::FSM::Lexer');

$file = tmpfile(" line 1 \n line 2 \\\n and 3 \n line 4 \\"); 

$lex = new_ok('MyLexer');
$lex->from_file($file);

t_get($file, 1, NAME => 'line', NUM => 1, "\n" => "\n");
is $lex->[5], " line 1 \n";
t_get($file, 2, NAME => 'line', NUM => 2);
is $lex->[5], " line 2 \\\n and 3 \n";
t_get($file, 3, NAME => 'and', NUM => 3, "\n" => "\n");
is $lex->[5], " line 2 \\\n and 3 \n";
t_get($file, 4, NAME => 'line', NUM => 4);
is $lex->[5], " line 4 \\\n";
t_get();


done_testing();
