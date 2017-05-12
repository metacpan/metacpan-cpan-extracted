#!perl

# $Id: expression.t,v 1.5 2010/10/01 11:02:26 Paulo Exp $

use strict;
use warnings;

use Test::More;

use_ok 'Parse::FSM';
require_ok 't/utils.pl';

unlink 'Parser.pm';

my $fsm;
my $parser;

#------------------------------------------------------------------------------
$fsm = new_ok('Parse::FSM');
$fsm->add_rule('start', '', '{1}');
isa_ok $parser = $fsm->parser, 'Parse::FSM::Driver';

#------------------------------------------------------------------------------
# _error_at EOF
eval {$parser->_error_at(undef, 0)};
is $@, "Expected start at EOF\n";

#------------------------------------------------------------------------------
# _error_at token
eval {$parser->_error_at([NUM => 10], 0)};
is $@, "Expected start at NUM\n";

#------------------------------------------------------------------------------
# add_rule errors - arguments
$fsm = new_ok('Parse::FSM');
eval { $fsm->add_rule() };
like $@, qr/missing arguments at t.*FSM-error.t/;

#------------------------------------------------------------------------------
# add_rule errors - ambiguous grammar
$fsm = new_ok('Parse::FSM');
		$fsm->add_rule('prog', '[stmt]', '{}');
eval {	$fsm->add_rule('prog', '[stmt]', ';', '{}'); };
like $@, qr/leaf and node at \(prog : \[stmt\]\) at t.*FSM-error.t/;

$fsm = new_ok('Parse::FSM');
		$fsm->add_rule('prog', '[stmt]', ';', '{}');
eval {	$fsm->add_rule('prog', '[stmt]', '{}'); };
like $@, qr/leaf not unique at \(prog : \[stmt\]\) at t.*FSM-error.t/;

#------------------------------------------------------------------------------
# _add_action errors
$fsm = new_ok('Parse::FSM');
eval { $fsm->add_rule('prog', '[stmt]', '') };
like $@, qr/action must be enclosed in \{\} at t.*FSM-error.t/;

$fsm = new_ok('Parse::FSM');
eval { $fsm->add_rule('prog', '[stmt]', ' { ') };
like $@, qr/action must be enclosed in \{\} at t.*FSM-error.t/;

$fsm = new_ok('Parse::FSM');
eval { $fsm->add_rule('prog', '[stmt]', ' {} x') };
like $@, qr/action must be enclosed in \{\} at t.*FSM-error.t/;

$fsm = new_ok('Parse::FSM');
eval { $fsm->add_rule('prog', '[stmt]', 'x {} ') };
like $@, qr/action must be enclosed in \{\} at t.*FSM-error.t/;

#------------------------------------------------------------------------------
# write_module errors
$fsm = new_ok('Parse::FSM');
eval { $fsm->write_module };
like $@, qr/name not defined at t.*FSM-error.t/; 

eval { $fsm->write_module('Parser') };
like $@, qr/start state not found at t.*FSM-error.t/; 

unlink 'Parser.pm';
$fsm = new_ok('Parse::FSM');
$fsm->add_rule('start', '', '{1}');
$fsm->write_module('Parser');
ok unlink 'Parser.pm';

unlink 't/Data/Parser.pm';
$fsm = new_ok('Parse::FSM');
$fsm->add_rule('start', '', '{1}');
$fsm->write_module('t::Data::Parser');
ok unlink 't/Data/Parser.pm';

#------------------------------------------------------------------------------
# _check_start_rule
$fsm = new_ok('Parse::FSM');
is $fsm->start_rule, undef;

$fsm->_check_start_rule('_temp');
is $fsm->start_rule, undef;

$fsm->_check_start_rule('prog');
is $fsm->start_rule, 'prog';

$fsm->_check_start_rule('expr');
is $fsm->start_rule, 'prog';

#------------------------------------------------------------------------------
unlink 'Parser.pm';
unlink 't/Data/Parser.pm';
done_testing;
