use strict;
use warnings;
use Test::More;
use Switch::Declare;

# Named constants and explicitly-typed scalar variables as case patterns.
#
#   * A bareword that names an inlinable `use constant` folds to its value at
#     compile time and is classified exactly like the literal it holds: a
#     numeric constant compiles to ==, a string constant to eq.
#   * A runtime variable cannot be classified at compile time, so the comparison
#     is stated explicitly: `case == $x` (numeric ==) or `case eq $x` (eq).
#   * Both stay undef/type-safe: an undef topic OR an undef variable neither
#     matches nor warns. This whole file runs under `use warnings` with no local
#     suppression.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

use constant FOO  => 1;
use constant NAME => "bob";
use constant PI   => 3.14;

# --- constants -----------------------------------------------------------
is( (switch(1)    { case FOO  { "n" } default { "D" } }), "n", "numeric constant matches" );
is( (switch(2)    { case FOO  { "n" } default { "D" } }), "D", "numeric constant misses" );
is( (switch("bob"){ case NAME { "s" } default { "D" } }), "s", "string constant matches" );
is( (switch("al") { case NAME { "s" } default { "D" } }), "D", "string constant misses" );
is( (switch(3.14) { case PI   { "f" } default { "D" } }), "f", "float constant matches" );

# a string constant is == semantics?  no - eq, like its literal
is( (switch("1")  { case FOO  { "n" } default { "D" } }), "n", "numeric constant: '1' == 1" );

# --- typed variables -----------------------------------------------------
my $n = 5;
my $s = "x";
is( (switch(5)   { case == $n { "h" } default { "D" } }), "h", "== \$var matches numerically" );
is( (switch(6)   { case == $n { "h" } default { "D" } }), "D", "== \$var misses" );
is( (switch("x") { case eq $s { "h" } default { "D" } }), "h", "eq \$var matches stringwise" );
is( (switch("y") { case eq $s { "h" } default { "D" } }), "D", "eq \$var misses" );

# == vs eq pick the comparison, not the value's type
my $five = 5;
is( (switch("5") { case == $five { "h" } default { "D" } }), "h", "==: '5' == 5" );
is( (switch(5)   { case eq $five { "h" } default { "D" } }), "h", "eq: 5 eq '5'" );

# package / our variables
our $G = 7;
is( (switch(7)   { case == $G { "h" } default { "D" } }), "h", "== matches an our variable" );
is( (switch(8)   { case == $G { "h" } default { "D" } }), "D", "== misses an our variable" );
$main::PKG = "hi";
is( (switch("hi"){ case eq $main::PKG { "h" } default { "D" } }), "h", "eq matches a package variable" );

# inline sub still closes over a typed-variable neighbour (no parser confusion)
is( (switch(10)  { case == $n { "a" } case sub { $_[0] > 9 } { "b" } default { "D" } }),
    "b", "== \$var arm coexists with an inline predicate arm" );

# --- =~ $var : regex match against a runtime pattern ---------------------
my $digits = qr/^\d+$/;
is( (switch("123") { case =~ $digits { "h" } default { "D" } }), "h", "=~ qr// matches" );
is( (switch("12a") { case =~ $digits { "h" } default { "D" } }), "D", "=~ qr// misses" );

my $ci = qr/foo/i;
is( (switch("xFOOy"){ case =~ $ci { "h" } default { "D" } }), "h", "=~ honours qr// flags (/i)" );

# a plain string operand is used as a pattern (like real =~)
my $sub = "ell";
is( (switch("hello"){ case =~ $sub { "h" } default { "D" } }), "h", "=~ string operand is a pattern" );

# undef-safe on both sides, and warning-free
my $undef_topic = undef;
is( (switch($undef_topic) { case =~ $digits { "x" } default { "D" } }), "D", "=~ undef topic -> default" );
my $upat = undef;
is( (switch("x")   { case =~ $upat { "x" } default { "D" } }), "D", "=~ undef pattern -> no match" );

# utf8 topic
my $eacute = qr/\x{e9}/;
is( (switch("caf\x{e9}"){ case =~ $eacute { "h" } default { "D" } }), "h", "=~ matches a utf8 topic" );

# coexists in a chain with == / eq
is( (switch("42") { case == $n { "n" } case =~ $digits { "rx" } default { "D" } }), "rx",
    "=~ arm coexists with == and eq arms" );

# a single '~' or bad operator is rejected
eval q{ my $r = switch("a"){ case =~ qr/x/ { 1 } default { 0 } }; 1 };
like( $@, qr/expected a scalar variable/, "=~ requires a variable operand (not a literal)" );

# --- undef / type safety -------------------------------------------------
my $u = undef;
is( (switch($u) { case == $n { "x" } case eq $s { "y" } default { "D" } }), "D",
    "undef topic matches neither == nor eq var" );

# an undef variable operand: no match, no warning
my $uv = undef;
is( (switch(5)   { case == $uv { "x" } default { "D" } }), "D", "undef == \$var does not match" );
is( (switch("a") { case eq $uv { "x" } default { "D" } }), "D", "undef eq \$var does not match" );

# a non-numeric variable against a numeric topic: no match, no warning
my $word = "hello";
is( (switch(5)   { case == $word { "x" } default { "D" } }), "D", "== \$var that isn't a number misses" );

# case undef still wins for an undef topic alongside typed-variable arms
is( (switch($u) { case == $n { "x" } case undef { "NULL" } default { "D" } }), "NULL",
    "case undef still catches an undef topic" );

# --- a bad bareword still errors, and names itself ----------------------
eval q{ my $r = switch(1) { case NOPE { "x" } default { "d" } }; 1 };
like( $@, qr/unexpected bareword 'NOPE'/, "an unknown bareword errors and names itself" );

# a single '=' is not a comparison operator
eval q{ my $v = 1; my $r = switch(1) { case = $v { "x" } default { "d" } }; 1 };
like( $@, qr/expected '=='/, "a single '=' is rejected with a clear message" );

# --- headline: no warnings anywhere above --------------------------------
is_deeply( \@warnings, [], "constants and typed variables produced no warnings" )
    or diag("unexpected warnings:\n", @warnings);

done_testing;
