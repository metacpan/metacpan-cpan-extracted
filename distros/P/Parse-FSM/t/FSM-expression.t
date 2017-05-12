#!perl

# $Id: expression.t,v 1.5 2010/10/01 11:02:26 Paulo Exp $

use 5.010;
use strict;
use warnings;

use Test::More;
use Data::Dump 'dump';

use_ok 'Parse::FSM';
require_ok 't/utils.pl';

#------------------------------------------------------------------------------
# test parsing using the FSM tables
# compile a parser for:
#		prog	: stmt<+;> ''		{ $item[0]}
#		stmt	: expr				{ $item[0] }
#		expr 	: term addop*		{ my $res = $item[0];
#									  $res += $_ for (@{$item[1]});
#									  $res }
#		addop	: '+' term			{   $item[1] }
#				| '-' term			{ - $item[1] }
#				;
#		term	: factor mulop*		{ my $res = $item[0];
#									  $res *= $_ for (@{$item[1]});
#									  $res }
#		mulop	: '*' factor		{     $item[1] }
#			 	| '/' factor		{ 1 / $item[1] }
#				;
#		factor	: 'NUM'				{   $item[0][1] }
#				| '-' 'NUM'			{ - $item[0][1] }
#				| '+' 'NUM'			{   $item[0][1] }
#				| '(' expr ')'		{   $item[1]    }
#				;

#------------------------------------------------------------------------------
# add_rule
my $fsm = new_ok('Parse::FSM');

$fsm->add_rule('prog', '[stmt]<+;>', '', '{ $item[0] }');
$fsm->add_rule('stmt', '[expr]', '{ $item[0] }');

$fsm->add_rule('expr', '[term]', '[addop]*', 
				'{ my $res = $item[0]; $res += $_ for (@{$item[1]}); $res }');

$fsm->add_rule('addop', '+', '[term]', 
				'{ $item[1] }');

$fsm->add_rule('addop', '-', '[term]', 
				'{ - $item[1] }');

$fsm->add_rule('term', '[factor]', '[mulop]*', 
				'{ my $res = $item[0]; $res *= $_ for (@{$item[1]}); $res }');

$fsm->add_rule('mulop', '*', '[factor]', 
				'{ $item[1] }');

$fsm->add_rule('mulop', '/', '[factor]', 
				'{ 1 / $item[1] }');

$fsm->add_rule('factor', 'NUM', 				'{ $item[0][1] }');
$fsm->add_rule('factor', '-', 'NUM', 			'{ - $item[1][1] }');
$fsm->add_rule('factor', '+', 'NUM', 			'{   $item[1][1] }');
$fsm->add_rule('factor', '(', '[expr]', ')',	'{ $item[1] }');

#------------------------------------------------------------------------------
# compute the FSM
$fsm->_compute_fsm;
diag explain($fsm) if $ENV{DEBUG};

#------------------------------------------------------------------------------
# load the module, call the parser
unlink 'Parser.pm';
$fsm->write_module('Parser', 'Parser.pm');
ok -f 'Parser.pm';

use_ok 'Parser';

my $parser = new_ok('Parser');

$parser->input(make_lexer("2"));
is $parser->parse('expr'), 2;
is $parser->peek_token, undef;

$parser->input(make_lexer("2"));
is $parser->parse_expr, 2;
is $parser->peek_token, undef;

$parser->input(make_lexer("+2"));
is $parser->parse_expr, 2;
is $parser->peek_token, undef;

$parser->input(make_lexer("-2"));
is $parser->parse_expr, -2;
is $parser->peek_token, undef;

$parser->input(make_lexer("4+-2"));
is $parser->parse_expr, 2;
is $parser->peek_token, undef;

$parser->input(make_lexer("1+2+3"));
is $parser->parse_expr, 6;
is $parser->peek_token, undef;

$parser->input(make_lexer("1+2+3"));
is $parser->parse_expr, 6;
is $parser->peek_token, undef;

$parser->input(make_lexer("6-2-2"));
is $parser->parse_expr, 2;
is $parser->peek_token, undef;

$parser->input(make_lexer("2+3*4"));
is $parser->parse_expr, 14;
is $parser->peek_token, undef;

$parser->input(make_lexer("(2+3)*4"));
is $parser->parse_expr, 20;
is $parser->peek_token, undef;

$parser->input(make_lexer("(2+3)*+4"));
is $parser->parse_expr, 20;
is $parser->peek_token, undef;

$parser->input(make_lexer("(2+3)*-4"));
is $parser->parse_expr, -20;
is $parser->peek_token, undef;

$parser->input(make_lexer("(2+-3)*-4"));
is $parser->parse_expr, 4;
is $parser->peek_token, undef;

$parser->input(make_lexer("2+"));
eval { $parser->parse_expr };
is $@, 'Expected one of ("(" "+" "-" NUM) at EOF'."\n";

$parser->input(make_lexer("1;1+2;1+2+3;1+2+3+4"));
is_deeply $parser->parse, [1, 3, 6, 10];
is $parser->peek_token, undef;

$parser->input(make_lexer("1;1+2;1+2+3;1+2+3+4"));
is_deeply $parser->parse_prog, [1, 3, 6, 10];
is $parser->peek_token, undef;

#------------------------------------------------------------------------------
# clean-up
unlink 'Parser.pm';

done_testing;
