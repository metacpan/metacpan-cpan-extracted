#!/usr/bin/perl -w

use strict;
use IO::File;

use Test::More tests => 51;

BEGIN {use_ok('Repl::Core::Parser')};
BEGIN {use_ok('Repl::Core::Eval')};
BEGIN {use_ok('Repl::Core::StreamBuffer')};

BEGIN {use_ok('Repl::Loop')};
BEGIN {use_ok('Repl::Cmd::MathCmd')};

my $parser = new Repl::Core::Parser();
my $eval = new Repl::Core::Eval();
Repl::Cmd::MathCmd::registerCommands($eval);
my $result;

# I. PARSER
# ---------

# Parse atoms.
#
$result = $parser->parseString("oele");
ok($result eq "oele", "parse atom test 1");
$result = $parser->parseString("0");
ok($result eq "0", "parse atom test 2");
$result = $parser->parseString("12345");
ok($result eq "12345", "parse atom test 3");
$result = $parser->parseString('"abc"');
ok($result eq "abc", "parse atom test 4");
$result = $parser->parseString('"\\n"');
ok($result eq "\n", "parse atom test 5");
$result = $parser->parseString('"\\t"');
ok($result eq "\t", "parse atom test 6");
$result = $parser->parseString('"\\\\"');
ok($result eq "\\", "parse atom test 7");

# i18n?
#
$result = $parser->parseString("(é è ü ö ï)");
#print $result;

# Parse lists.
#
$result = $parser->parseString("()");
ok(ref($result) eq "ARRAY", "parse list test 1");
ok(scalar(@$result) == 0, "parse list test 2");
$result = $parser->parseString("(0 1 2 3 4 5 6 7 8 9)");
ok(ref($result) eq "ARRAY", "parse list test 3");
ok(scalar(@$result) == 10, "parse list test 4");
$result = $parser->parseString("((((((((((x))))))))))");
ok($result->[0]->[0]->[0]->[0]->[0]->[0]->[0]->[0]->[0]->[0] eq "x", "parse list test 5");

# Parse a quoted expression.
# It should result in a [quote ["a", "b", "c", "d", "e"]] structure.
#
$result = $parser->parseString("'(a b c d e)");
ok(ref($result) eq 'ARRAY', "Parse quoted expr test 1");
ok($result->[0] eq 'quote', "Parse quoted expr test 2" );
ok(ref($result->[1]) eq 'ARRAY', "Parse quoted expr test 3");

# II. EVAL
# --------

# Define a binding oele=...
# Check that the binding was effectively created.
# 
$eval->evalExpr($parser->parseString("(defvar oele=plopperdeplop)"));
$result = $eval->evalExpr($parser->parseString("\$oele"));
ok($result eq "plopperdeplop", 'defvar');

# Try to change an unknown binding.
# It should generate an error stating that you tried to change an unknown binding.
#
eval {$result = $eval->evalExpr($parser->parseString("(set thiswasneverdefined=alloallo)"))};
ok($@ =~ /no binding/, "Change unexisting binding.");

# Evaluate a let/let* block.
#
$result = $eval->evalExpr($parser->parseString("(let (oele=bruno boele=fons makkis=bart voele=teck) \$oele)"));
ok($result eq "bruno", 'let block');
# c evaluates to $b which is evaluated in global context.
$result = $eval->evalExpr($parser->parseString("(progn (defvar a 10) (defvar b 20) (defvar c 30) (let (a=13 b=\$a c=\$b) \$c))"));
ok($result==20, 'let block');
# c evaluates to $b which is bound in local context.
$result = $eval->evalExpr($parser->parseString("(progn (defvar a 10) (defvar b 20) (defvar c 30) (let* (a=13 b=\$a c=\$b) \$c))"));
ok($result==13, 'let* block');
# Change a defvar binding.
$result = $eval->evalExpr($parser->parseString("(progn (defvar a 10) (set a 13) \$a)"));
ok($result==13, 'set of defvar var');
# Change a let binding.
$result = $eval->evalExpr($parser->parseString("(progn (defvar a 10) (let (a=13) (set a=17)) \$a)"));
ok($result==10, 'set of let var');
# Change a let* binding.
$result = $eval->evalExpr($parser->parseString("(progn (defvar a 10) (let* (a=13) (set a=17)) \$a)"));
ok($result==10, 'set of let var');

# Lambda evaluation.
# Create a lambda and evaluate it on different arguments.
#
$result = $eval->evalExpr($parser->parseString("(let (fie=(lambda (par) (if (eq \$par uno) een twee )) arg=uno) (\$fie \$arg))"));
ok($result eq 'een', 'lambda');
$result = $eval->evalExpr($parser->parseString("(let (fie=(lambda (par) (if (eq \$par uno) een twee )) arg=duo) (\$fie \$arg))"));
ok($result eq 'twee', 'lambda');

# Boolean operators
#------------------

# Boolean primitives.
#
$result = $eval->evalExpr($parser->parseString("(if (and true True TRue on ON On oN Yes yes YES yEs 1 t T 1) pos neg)"));
ok($result eq "pos", 'truthy values');
$result = $eval->evalExpr($parser->parseString("(if (or false False Off OFF NO no nO f 0 F) pos neg)"));
ok($result eq "neg", 'falsy values');

# eq operator
#
$result = $eval->evalExpr($parser->parseString("(if (eq a a) equal different)"));
ok($result eq "equal", "eq test");
$result = $eval->evalExpr($parser->parseString("(if (eq a b) equal different)"));
ok($result eq "different", "!eq test");

# or
#
$result = $eval->evalExpr($parser->parseString("(if (or (eq a b) (eq c c)) pos neg)"));
ok($result eq "pos", 'or test');
$result = $eval->evalExpr($parser->parseString("(if (or (eq a b) (eq c d)) pos neg)"));
ok($result eq "neg", '!or test');

# and
#
$result = $eval->evalExpr($parser->parseString("(if (and (eq a a) (eq c c)) pos neg)"));
ok($result eq "pos", 'and test');
#
$result = $eval->evalExpr($parser->parseString("(if (and (eq a a) (eq c d)) pos neg)"));
ok($result eq "neg", '!and test');

# not
#
$result = $eval->evalExpr($parser->parseString("(if (not (and (eq a b) (eq c c))) pos neg)"));
ok($result eq "pos", 'not test');
#
$result = $eval->evalExpr($parser->parseString("(if (not (and (eq a a) (eq c c))) pos neg)"));
ok($result eq "neg", '!not test');

# while
$result = $eval->evalExpr($parser->parseString("(progn (defvar a 10) (while \$a (set a (- \$a 1))) \$a)"));
ok($result==0, 'while test');

# Function calls and recursion
# ----------------------------

# Plain call.
$result = $eval->evalExpr($parser->parseString("(fac 10)"));
ok($result==3628800, 'recursion test');
# Direct funcall.
$result = $eval->evalExpr($parser->parseString("(funcall fac 10)"));
ok($result==3628800, 'funcall call');
# Lambda call
$result = $eval->evalExpr($parser->parseString("((lambda (x) (+ \$x 1)) 13)"));
ok($result==14, 'lambda call');

# Test stream parsing
# -------------------
my $io = IO::File->new('t/test-data.txt');
my $streambuf = new Repl::Core::StreamBuffer($io);
my $streamparser = new Repl::Core::Parser();
# Read the first expression.
$result = $streamparser->parseExpression($streambuf);
ok(ref($result) eq 'ARRAY', "file buffer 1st expression.");
ok(ref($result->[0]) eq 'Repl::Core::Pair', "file buffer pair");
ok($result->[0]->getLeft() eq "oele" , "file buffer pair contents");
ok($result->[0]->getRight() eq "boele", "file buffer pair contents");
# Read the second expression.
$result = $streamparser->parseExpression($streambuf);
ok(ref($result) eq 'ARRAY', "file buffer 2nd expression");
ok($result->[0] eq "Dit is een string", "file buffer 2nd expression contents");
# EOF
$result = $streamparser->parseExpression($streambuf);
ok(ref($result) eq "Repl::Core::Token" && $result->isEof(), "file buffer eof")