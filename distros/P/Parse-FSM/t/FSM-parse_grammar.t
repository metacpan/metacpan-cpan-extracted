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
# prolog and epilog
$fsm = new_ok('Parse::FSM');
$fsm->parse_grammar(<<'END');
	main : 'NUM' ;
END
is $fsm->prolog, undef;
is $fsm->epilog, undef;

$fsm = new_ok('Parse::FSM');
$fsm->parse_grammar(<<'END');
	{prolog}
	main : 'NUM' ;
END
is $fsm->prolog, "prolog";
is $fsm->epilog, undef;

$fsm = new_ok('Parse::FSM');
$fsm->parse_grammar(<<'END');
	{prolog}
	main : 'NUM' ;
	{epilog}
END
is $fsm->prolog, "prolog";
is $fsm->epilog, "epilog";

$fsm = new_ok('Parse::FSM');
$fsm->parse_grammar(<<'END');
	main : 'NUM' ;
	{epilog}
END
is $fsm->prolog, undef;
is $fsm->epilog, "epilog";

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};

END
like $@, qr/^Expected one of \("<start" NAME\) at EOF at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	.
END
like $@, qr/^Expected one of \("<start" NAME\) at "." at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	main
END
like $@, qr/^Expected ":" at EOF at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	main : term '
END
like $@, qr/^Cannot parse quoted string at "'\\n" at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	main : term "
END
like $@, qr/^Cannot parse quoted string at "\\"\\n" at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	main : term {
END
like $@, qr/^Cannot parse code block at "\{\\n" at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	main : term { { }
END
like $@, qr/^Cannot parse code block at "\{ \{ \}\\n" at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	main : term {}
END
like $@, qr/^Expected ";" at EOF at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	main : term {}
		 | factor {}
END
like $@, qr/^Expected ";" at EOF at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	_main : term ;
END
like $@, qr/^Expected one of \("<start" NAME\) at _ at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# rules : syntax error
$fsm = new_ok('Parse::FSM');
eval {$fsm->parse_grammar(<<'END')};
	main : term ;
	!
END
like $@, qr/^Expected EOF at "!" at t.FSM-parse_grammar.t/;

#------------------------------------------------------------------------------
# main : term '+' term ; 
# term : NUM ;
$fsm = new_ok('Parse::FSM');
$fsm->parse_grammar(<<'END');
	main : term '+' term '' ; 
	term : 'NUM' ;
END
isa_ok $parser = $fsm->parser, 'Parse::FSM::Driver';

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("2"));
eval {$parser->parse};
is $@, "Expected \"+\" at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("2+"));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("2+3"));
is_deeply $parser->parse, [[NUM => 2], ["+" => "+"], [NUM => 3]];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# main : term '+' term ; 
# term : NUM ;
$fsm = new_ok('Parse::FSM');
$fsm->parse_grammar(<<'END');
	main : term '+' term ''	{ $item[0] + $item[2] }; 	# add
	term : 'NUM' 			{ $item[0][1] };			# value
END
isa_ok $parser = $fsm->parser, 'Parse::FSM::Driver';

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("2"));
eval {$parser->parse};
is $@, "Expected \"+\" at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("2+"));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("2+3"));
is_deeply $parser->parse, 5;
is $parser->get_token, undef;

#------------------------------------------------------------------------------
#  main   : (number | name)+ <eof> ;
#  number : 'NUMBER' { $item[0][1] } ; # comment
#  name   : 'NAME'   { $item[0][1] } ; # comment
$fsm = new_ok('Parse::FSM');
$fsm->parse_grammar(<<'END');
	main   : (number | name)+ <eof> { $item[0] } ;
	number : 'NUM' 					{ $item[0][1] } ; # comment
	name   : 'NAME'   				{ $item[0][1] } ; # comment
END
isa_ok $parser = $fsm->parser, 'Parse::FSM::Driver';

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected one of (NAME NUM) at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("2"));
is_deeply $parser->parse, [2];
is $parser->get_token, undef;

$parser->input(make_lexer("2 4"));
is_deeply $parser->parse, [2, 4];
is $parser->get_token, undef;

$parser->input(make_lexer("2 a 4"));
is_deeply $parser->parse, [2, 'a', 4];
is $parser->get_token, undef;

$parser->input(make_lexer("2!"));
eval {$parser->parse};
is $@, "Expected EOF at \"!\"\n";
is_deeply $parser->get_token, ["!" => "!"];
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# expr : <list: number '-' number> ;
$fsm = new_ok('Parse::FSM');
$fsm->parse_grammar(<<'END');
	expr   : <list: number '-' number> <eof>
						{ 	my @ops = @{$item[0]};
							@ops or die "empty ops\n";
							my $ret = shift @ops;
							while (@ops) {
								shift(@ops) eq '-' or die "expected -\n";
								$ret -= shift @ops;
							}
							return $ret;
						} ;
	number : 'NUM' 		{ $item[0][1] } ;
END
isa_ok $parser = $fsm->parser, 'Parse::FSM::Driver';

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("2!"));
eval {$parser->parse};
is $@, "Expected EOF at \"!\"\n";
is_deeply $parser->get_token, ["!" => "!"];
is $parser->get_token, undef;

$parser->input(make_lexer("2"));
is $parser->parse, 2;
is $parser->get_token, undef;

$parser->input(make_lexer("3-2"));
is $parser->parse, 1;
is $parser->get_token, undef;

$parser->input(make_lexer("10-2-2"));
is $parser->parse, 6;
is $parser->get_token, undef;

#------------------------------------------------------------------------------
# expr : <list: number ('+'|'-') number> ;
$fsm = new_ok('Parse::FSM');
$fsm->parse_grammar(<<'END');
	expr   : <list: number ('+'|'-') number> <eof>
						{ 	my @ops = @{$item[0]};
							@ops or die "empty ops\n";
							my $ret = shift @ops;
							while (@ops) {
								my $op = shift(@ops)->[0];
								if ($op eq '+') {
									$ret += shift @ops;
								}
								elsif ($op eq '-') {
									$ret -= shift @ops;
								}
								else {
									die "expected + or -\n";
								}
							}
							return $ret;
						} ;
	number : 'NUM' 		{ $item[0][1] } ;
END
isa_ok $parser = $fsm->parser, 'Parse::FSM::Driver';

$parser->input(make_lexer(""));
eval {$parser->parse};
is $@, "Expected NUM at EOF\n";
is $parser->get_token, undef;

$parser->input(make_lexer("2!"));
eval {$parser->parse};
is $@, "Expected EOF at \"!\"\n";
is_deeply $parser->get_token, ["!" => "!"];
is $parser->get_token, undef;

$parser->input(make_lexer("2"));
is $parser->parse, 2;
is $parser->get_token, undef;

$parser->input(make_lexer("3-2"));
is $parser->parse, 1;
is $parser->get_token, undef;

$parser->input(make_lexer("10-2-2"));
is $parser->parse, 6;
is $parser->get_token, undef;

$parser->input(make_lexer("10-2-2+4"));
is $parser->parse, 10;
is $parser->get_token, undef;

$parser->input(make_lexer("10-2-2+4+3"));
is $parser->parse, 13;
is $parser->get_token, undef;


#------------------------------------------------------------------------------
done_testing;
