#!perl

# $Id: expression.t,v 1.5 2010/10/01 11:02:26 Paulo Exp $

use strict;
use warnings;

use Test::More;

use_ok 'Parse::FSM';
require_ok 't/utils.pl';

my $fsm;
my $parser;

#------------------------------------------------------------------------------
# start : NAME
t_grammar(
	[	["start", "NAME", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : 'NAME' {$item[0][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("1"));
eval {$parser->parse};
is $@, "Expected NAME at NUM\n";
is_deeply $parser->get_token, [NUM => 1];

$parser->input(make_lexer("a"));
is_deeply $parser->parse, "a";
is $parser->get_token, undef;

$parser->input(make_lexer("a b"));
is_deeply $parser->parse, "a";
is_deeply $parser->get_token, [NAME => "b"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [name]
# name  : NAME
t_grammar(
	[	["start", "[name]", '{$item[0]}'],
		["name", "NAME", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : name   {$item[0]} ;
		name  : 'NAME' {$item[0][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("1"));
eval {$parser->parse};
is $@, "Expected NAME at NUM\n";
is_deeply $parser->get_token, [NUM => 1];

$parser->input(make_lexer("a"));
is_deeply $parser->parse, "a";
is $parser->get_token, undef;

$parser->input(make_lexer("a b"));
is_deeply $parser->parse, "a";
is_deeply $parser->get_token, [NAME => "b"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [name] EOF
# name  : NAME
t_grammar(
	[	["start", "[name]", '', '{$item[0]}'],
		["name", "NAME", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : name '' {$item[0]} ;
		name  : 'NAME'  {$item[0][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("1"));
eval {$parser->parse};
is $@, "Expected NAME at NUM\n";
is_deeply $parser->get_token, [NUM => 1];

$parser->input(make_lexer("a"));
is_deeply $parser->parse, "a";
is $parser->get_token, undef;

$parser->input(make_lexer("a b"));
eval {$parser->parse};
is $@, "Expected EOF at NAME\n";
is_deeply $parser->get_token, [NAME => "b"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : NAME EOF
t_grammar(
	[	["start", "NAME", '', '{$item[0][1]}']	],
	undef,
	<<'END');
		start : 'NAME' '' {$item[0][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("1"));
eval {$parser->parse};
is $@, "Expected NAME at NUM\n";
is_deeply $parser->get_token, [NUM => 1];

$parser->input(make_lexer("a"));
is_deeply $parser->parse, "a";
is $parser->get_token, undef;

$parser->input(make_lexer("a b"));
eval {$parser->parse};
is $@, "Expected EOF at NAME\n";
is_deeply $parser->get_token, [NAME => "b"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : NAME "\n" EOF
t_grammar(
	[	["start", "NAME", "\n", '', '{$item[0][1]}']	],
	undef,
	<<'END');
		start : 'NAME' "\n" '' {$item[0][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("1"));
eval {$parser->parse};
is $@, "Expected NAME at NUM\n";
is_deeply $parser->get_token, [NUM => 1];

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected \"\\n\" at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a\n"));
is_deeply $parser->parse, "a";
is $parser->get_token, undef;

$parser->input(make_lexer("a\nb"));
eval {$parser->parse};
is $@, "Expected EOF at NAME\n";
is_deeply $parser->get_token, [NAME => "b"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : NAME "=" NUM EOF
t_grammar(
	[	["start", "NAME", "=", "NUM", '', '{$item[2][1]}']	],
	undef,
	<<'END');
		start : 'NAME' "=" 'NUM' '' {$item[2][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected \"=\" at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a="));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a=10"));
is $parser->parse, 10;
is $parser->get_token, undef;

$parser->input(make_lexer("a=10 10"));
eval {$parser->parse};
is $@, "Expected EOF at NUM\n";
is_deeply $parser->get_token, [NUM => 10];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [expr] EOF
# expr  : NAME "=" NUM
#       | NAME "=" NAME ;
t_grammar(
	[	["expr", "NAME", "=", "NUM", '{$item[2][1]}'],
		["expr", "NAME", "=", "NAME", '{$item[2][1]}'],
		["start", "[expr]", '', '{$item[0]}']	],
	"start",
	<<'END');
		expr  : 'NAME' "=" 'NUM' {$item[2][1]} ;
		expr  : 'NAME' "=" 'NAME'{$item[2][1]} ;
		start : expr ''          {$item[0]} ;
		
		<start : start >
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected \"=\" at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a="));
eval {$parser->parse};
is $@, "Expected one of (NAME NUM) at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a=10"));
is $parser->parse, 10;
is $parser->get_token, undef;

$parser->input(make_lexer("a=a"));
is $parser->parse, "a";
is $parser->get_token, undef;

$parser->input(make_lexer("a=a 10"));
eval {$parser->parse};
is $@, "Expected EOF at NUM\n";
is_deeply $parser->get_token, [NUM => 10];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [expr] EOF
# expr  : NAME "=" NUM
#       | NAME "=" NAME ;
t_grammar(
	[	["expr", "NAME", "=", ["NUM", "NAME"], '{$item[2][1]}'],
		["start", "[expr]", '', '{$item[0]}']	],
	"start",
	<<'END');
		expr  : 'NAME' "=" 'NUM' {$item[2][1]} 
		      | 'NAME' "=" 'NAME'{$item[2][1]} ;
		start : expr ''          {$item[0]} ;
		
		<start : start >
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected \"=\" at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a="));
eval {$parser->parse};
is $@, "Expected one of (NAME NUM) at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a=10"));
is $parser->parse, 10;
is $parser->get_token, undef;

$parser->input(make_lexer("a=a"));
is $parser->parse, "a";
is $parser->get_token, undef;

$parser->input(make_lexer("a=a 10"));
eval {$parser->parse};
is $@, "Expected EOF at NUM\n";
is_deeply $parser->get_token, [NUM => 10];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [name] "=" (NUM | NAME) EOF
#		| [name] "!" EOF
# name  : NAME
t_grammar(
	[	["name", "NAME", '{$item[0][1]}'],
		["start", "[name]", "=", ["NUM", "NAME"], '', '{$item[2][1]}'],
		["start", "[name]", "!", '', '{$item[0]}']	],
	"start",
	<<'END');
		name  : 'NAME' {$item[0][1]} ;
		start : name "=" 'NUM'  '' {$item[2][1]} 
		      | name "=" 'NAME' '' {$item[2][1]} 
			  | name "!" ''        {$item[0]} ;
		
		<start : start >
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("="));
eval {$parser->parse};
is $@, "Expected NAME at \"=\"\n";
is_deeply $parser->get_token, ["=" => "="];
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected one of (\"!\" \"=\") at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a="));
eval {$parser->parse};
is $@, "Expected one of (NAME NUM) at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("a=10"));
is $parser->parse, 10;
is $parser->get_token, undef;

$parser->input(make_lexer("a=a"));
is $parser->parse, "a";
is $parser->get_token, undef;

$parser->input(make_lexer("a!"));
is $parser->parse, "a";
is $parser->get_token, undef;

$parser->input(make_lexer("a=a 10"));
eval {$parser->parse};
is $@, "Expected EOF at NUM\n";
is_deeply $parser->get_token, [NUM => 10];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [const] NAME ''	# const inserts number as vNNN to be loaded by NAME
# const : NUM
t_grammar(
	[	['const', 'NUM', 
			   '{ my $value = $item[0][1];
			      $self->unget_token([NAME => "v".$value]);
				  return $value;
				}'],
		['start', '[const]', 'NAME', '',
			   '{$item[1]}']	],
	"start",
	<<'END');
		const : 'NUM' 
			    { my $value = $item[0][1];
			      $self->unget_token([NAME => "v".$value]);
				  return $value;
				} ;
		start : const 'NAME' '' {$item[1]} ;
		
		<start : start >
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("10"));
is_deeply $parser->parse, [NAME => "v10"];
is $parser->get_token, undef;

$parser->input(make_lexer("10 10"));
eval {$parser->parse};
is $@, "Expected EOF at NUM\n";
is_deeply $parser->get_token, [NUM => 10];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [num]?
# num   :  NUM
t_grammar(
	[	["start", "[num]?", '{$item[0]}'],
		["num", "NUM", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : num ? {$item[0]} ;
		num   : 'NUM' {$item[0][1]} ;
END

$parser->input(make_lexer(""));
is_deeply $parser->parse, [];
is $parser->get_token, undef;

$parser->input(make_lexer("10"));
is_deeply $parser->parse, [10];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11"));
is_deeply $parser->parse, [10];
is_deeply $parser->get_token, [NUM => 11];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [num]? EOF
# num   :  NUM
t_grammar(
	[	["start", "[num]?", '', '{$item[0]}'],
		["num", "NUM", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : num ? '' {$item[0]} ;
		num   : 'NUM'    {$item[0][1]} ;
END

$parser->input(make_lexer(""));
is_deeply $parser->parse, [];
is $parser->get_token, undef;

$parser->input(make_lexer("10"));
is_deeply $parser->parse, [10];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11"));
eval {$parser->parse};
is $@, "Expected EOF at NUM\n";
is_deeply $parser->get_token, [NUM => 11];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [num]*
# num   :  NUM
t_grammar(
	[	["start", "[num]*", '{$item[0]}'],
		["num", "NUM", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : num *    {$item[0]} ;
		num   : 'NUM'    {$item[0][1]} ;
END

$parser->input(make_lexer(""));
is_deeply $parser->parse, [];
is $parser->get_token, undef;

$parser->input(make_lexer("10"));
is_deeply $parser->parse, [10];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11"));
is_deeply $parser->parse, [10, 11];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11 12"));
is_deeply $parser->parse, [10, 11, 12];
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
is_deeply $parser->parse, [];
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

$parser->input(make_lexer("10 a"));
is_deeply $parser->parse, [10];
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [num]* EOF
# num   :  NUM
t_grammar(
	[	["start", "[num]*", '', '{$item[0]}'],
		["num", "NUM", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : num * '' {$item[0]} ;
		num   : 'NUM'    {$item[0][1]} ;
END

$parser->input(make_lexer(""));
is_deeply $parser->parse, [];
is $parser->get_token, undef;

$parser->input(make_lexer("10"));
is_deeply $parser->parse, [10];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11"));
is_deeply $parser->parse, [10, 11];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11 12"));
is_deeply $parser->parse, [10, 11, 12];
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected EOF at NAME\n";
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

$parser->input(make_lexer("10 a"));
eval {$parser->parse};
is $@, "Expected EOF at NAME\n";
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [num]+
# num   :  NUM
t_grammar(
	[	["start", "[num]+", '{$item[0]}'],
		["num", "NUM", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : num +    {$item[0]} ;
		num   : 'NUM'    {$item[0][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("10"));
is_deeply $parser->parse, [10];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11"));
is_deeply $parser->parse, [10, 11];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11 12"));
is_deeply $parser->parse, [10, 11, 12];
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected NUM at NAME\n";
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

$parser->input(make_lexer("10 a"));
is_deeply $parser->parse, [10];
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [num]+ EOF
# num   :  NUM
t_grammar(
	[	["start", "[num]+", '', '{$item[0]}'],
		["num", "NUM", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : num + '' {$item[0]} ;
		num   : 'NUM'    {$item[0][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("10"));
is_deeply $parser->parse, [10];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11"));
is_deeply $parser->parse, [10, 11];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11 12"));
is_deeply $parser->parse, [10, 11, 12];
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected NUM at NAME\n";
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

$parser->input(make_lexer("10 a"));
eval {$parser->parse};
is $@, "Expected EOF at NAME\n";
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [num]<+,>
# num   :  NUM
t_grammar(
	[	["start", "[num]<+,>", '{$item[0]}'],
		["num", "NUM", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : num <+ , >    {$item[0]} ;
		num   : 'NUM'         {$item[0][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("10"));
is_deeply $parser->parse, [10];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11"));
is_deeply $parser->parse, [10];
is_deeply $parser->get_token, [NUM => 11];
is $parser->get_token, undef;

$parser->input(make_lexer("10,"));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("10,11"));
is_deeply $parser->parse, [10, 11];
is $parser->get_token, undef;

$parser->input(make_lexer("10, 11, 12"));
is_deeply $parser->parse, [10, 11, 12];
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected NUM at NAME\n";
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

$parser->input(make_lexer("10 a"));
is_deeply $parser->parse, [10];
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# start : [num]<+,> EOF
# num   :  NUM
t_grammar(
	[	["start", "[num]<+,>", '', '{$item[0]}'],
		["num", "NUM", '{$item[0][1]}']	],
	undef,
	<<'END');
		start : num <+,> ''   {$item[0]} ;
		num   : 'NUM'         {$item[0][1]} ;
END

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("10"));
is_deeply $parser->parse, [10];
is $parser->get_token, undef;

$parser->input(make_lexer("10 11"));
eval {$parser->parse};
is $@, "Expected EOF at NUM\n";
is_deeply $parser->get_token, [NUM => 11];
is $parser->get_token, undef;

$parser->input(make_lexer("10,"));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("10,11"));
is_deeply $parser->parse, [10, 11];
is $parser->get_token, undef;

$parser->input(make_lexer("10, 11, 12"));
is_deeply $parser->parse, [10, 11, 12];
is $parser->get_token, undef;

$parser->input(make_lexer("a"));
eval {$parser->parse};
is $@, "Expected NUM at NAME\n";
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;

$parser->input(make_lexer("10 a"));
eval {$parser->parse};
is $@, "Expected EOF at NAME\n";
is_deeply $parser->get_token, [NAME => "a"];
is $parser->get_token, undef;


#------------------------------------------------------------------------------
done_testing;


#------------------------------------------------------------------------------
sub t_grammar {
	my($rules, $start_rule, $grammar) = @_;
	my $test = "[line ".(caller)[2]."]";
	
	# build with add_rule
	$fsm = new_ok('Parse::FSM');
	for my $rule (@$rules) {
		$fsm->add_rule(@$rule);
	}
	defined($start_rule) and $fsm->start_rule($start_rule);
	isa_ok $parser = $fsm->parser, 'Parse::FSM::Driver';

	# build with parse_grammar
	my $fsm2 = new_ok('Parse::FSM');
	$fsm2->parse_grammar($grammar);
	isa_ok my $parser2 = $fsm2->parser, 'Parse::FSM::Driver';
	
	# test that they are equivalent
	is_deeply $fsm, $fsm2, $test;
}
