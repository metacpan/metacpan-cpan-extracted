#!perl

# $Id: expression.t,v 1.5 2010/10/01 11:02:26 Paulo Exp $

use strict;
use warnings;

use Test::More;

use_ok 'Parse::FSM::Driver';
require_ok 't/utils.pl';

my $parser;

#------------------------------------------------------------------------------
# build a parser to add two numbers
$parser = new_ok('Parse::FSM::Driver');

$parser->_start_state(1);

# index
$parser->_state_table->[0] = { expr => 1, num => 4 };

# expr
$parser->_state_table->[1] = { NUM => [4, 2] };
$parser->_state_table->[2] = { "+" => 3 };
$parser->_state_table->[3] = { NUM => [4, 
									sub {
										my($self, @args) = @_; 
										return $args[0]+$args[2];
									} ] };
# num
$parser->_state_table->[4] = { NUM => sub {
										my($self, @args) = @_; 
										return $args[0][1];
									} };

#------------------------------------------------------------------------------
# test parse
$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";

$parser->input(make_lexer("1"));
eval {$parser->parse};
is $@, "Expected \"+\" at EOF\n";

$parser->input(make_lexer("1+"));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";

$parser->input(make_lexer("1+2"));
is $parser->parse, 3;
is $parser->peek_token, undef;

$parser->input(make_lexer("1+2;"));
is $parser->parse, 3;
is_deeply $parser->peek_token, [";" => ";"];

#------------------------------------------------------------------------------
# test input / peek / get / unget
$parser = new_ok('Parse::FSM::Driver');

is $parser->input->(), 	undef;

is $parser->peek_token, undef;
is $parser->get_token, 	undef;

$parser->unget_token(1..3);

is $parser->peek_token, 1;
is $parser->get_token, 	1;

is $parser->peek_token, 2;
is $parser->get_token, 	2;

is $parser->peek_token, 3;
is $parser->get_token, 	3;

is $parser->peek_token, undef;
is $parser->get_token, 	undef;

my @input = (1..3);

$parser->input(sub {shift @input});

is $parser->peek_token, 1;
is $parser->get_token, 	1;

is $parser->peek_token, 2;
is $parser->get_token, 	2;

$parser->unget_token(4..5);

is $parser->peek_token, 4;
is $parser->get_token, 	4;

is $parser->peek_token, 5;
is $parser->get_token, 	5;

is $parser->peek_token, 3;
is $parser->get_token, 	3;

is $parser->peek_token, undef;
is $parser->get_token, 	undef;

#------------------------------------------------------------------------------
# test user pointer
$parser = new_ok('Parse::FSM::Driver');

is_deeply $parser->user, {};

$parser->user([]);
$parser->user->[0] = 1;
$parser->user->[1] = 2;

is_deeply $parser->user, [1, 2];

#------------------------------------------------------------------------------
done_testing;
