use strict;
use warnings;
use Carp ();
use Test::More;

BEGIN {
  use_ok 'Params::PatternMatch' => qw/as case match otherwise rest then/;
}

sub factorial {
  match @_ => as {
    my $n;
    case 0 => then { 1 };
    case $n => then { $n * factorial($n - 1) };
    otherwise { Carp::croak('factorial: requires exactly 1 argument.') };
  };
}

is factorial(0), 1;
is factorial(1), 1;
is factorial(2), 2;
is factorial(3), 6;
is factorial(4), 24;
is factorial(5), 120;
my $n = 5;
is factorial($n), 120;
is $n, 5, 'Argument is never modified unless you explicitly assign.';

eval { factorial(1 .. 10) };
like $@, qr/factorial: requires exactly 1 argument./;

sub set_42 {
  match @_ => as {
    otherwise { $_[0] = 42 };
  };
}

my $x;
set_42($x);
is $x, 42, q/@_ is an alias of match()'s arguments./;

sub sum {
  match @_ => as {
    my ($n, @rest);
    case +() => then { 0 };
    case $n, rest(@rest) => then { $n + sum(@rest) }
  };
}

is sum, 0;
is sum(1), 1;
is sum(1 .. 10), 55;

done_testing;
