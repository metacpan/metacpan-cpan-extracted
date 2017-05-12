#perl -T

use Test::More 'no_plan';

BEGIN { use_ok('Shell::Perl'); }

my $sh = Shell::Perl->new;


$_ = ' $_ = 1000 ';
my $val = $sh->eval($_);
is($val, 1000);

$_ = ' $_ ';

my $val2 = $sh->eval($_);
TODO: {
    local $TODO = 'needs separating the REPL and the interpreter states';
    is($val2, 1000);
}

# this test script touches at a very sensitive
# issue in the implementation of a REPL -
# the state of the loop must be kept separate
# from the state of the running interpreter.
# By state, we mean those global variables like
# $_ and everything else.

