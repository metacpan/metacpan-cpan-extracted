# some forms of "use autouse ..."
use autouse TestA => qw(foo bar);
use autouse "TestB", qw(foo bar);

# "use if ..." (note the function call in COND)
sub frobnicate { 1 }
use if frobnicate(), TestC => qw(quux);
