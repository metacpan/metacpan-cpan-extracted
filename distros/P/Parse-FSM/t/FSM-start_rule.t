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
$fsm->add_rule("name",   "NAME", '', '{$item[0][1]}');
$fsm->add_rule("number", "NUM",  '', '{$item[0][1]}');
$fsm->write_module('Parser', 'Parser.pm');
use_ok 'Parser';

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("")]);
eval {$parser->parse};
is $@, "Expected NAME at EOF\n";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("")]);
eval {$parser->parse("name")};
is $@, "Expected NAME at EOF\n";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("")]);
eval {$parser->parse_name};
is $@, "Expected NAME at EOF\n";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("")]);
eval {$parser->parse("number")};
is $@, "Expected NUM at EOF\n";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("")]);
eval {$parser->parse_number};
is $@, "Expected NUM at EOF\n";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("")]);
eval {$parser->parse("no_rule")};
like $@, qr/Rule no_rule not found at t.FSM-start_rule.t/;

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("a")]);
is_deeply $parser->parse, "a";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("a")]);
is_deeply $parser->parse("name"), "a";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("a")]);
is_deeply $parser->parse_name, "a";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("a")]);
eval {$parser->parse("number")};
is $@, "Expected NUM at NAME\n";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer("a")]);
eval {$parser->parse_number};
is $@, "Expected NUM at NAME\n";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer(24)]);
is_deeply $parser->parse_number, 24;

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer(24)]);
is_deeply $parser->parse("number"), 24;

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer(24)]);
eval {$parser->parse};
is $@, "Expected NAME at NUM\n";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer(24)]);
eval {$parser->parse_name};
is $@, "Expected NAME at NUM\n";

#------------------------------------------------------------------------------
$parser = new_ok('Parser', [input => make_lexer(24)]);
eval {$parser->parse("name")};
is $@, "Expected NAME at NUM\n";

#------------------------------------------------------------------------------
# clean-up
unlink 'Parser.pm';

done_testing;
