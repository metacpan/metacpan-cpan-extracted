use strict;
use warnings;

use Test::More;

use Params::Lazy delay => "^";
sub delay {
   my $code = shift;
   print("ok 1 - Inside the delayed sub\n");
   force($code);
   print("ok 3 - After the delayed code\n");
}

delay print("ok 2 - Delayed code\n");

my $builder = Test::More->builder();
$builder->current_test(3);

my $msg = "force() requires a delayed argument";
eval { force(undef) };
like($@, qr/\Q$msg/, "force(undef) fails gracefully");
eval { force(1) };
like($@, qr/\Q$msg/, "force(1) fails gracefully");
eval { force(\1) };
like($@, qr/\Q$msg/, "force(\\1) fails gracefully");

eval { Params::Lazy->import("one") };
like($@, qr/uneven list of values/, "->import throws an exception on nonsensical parameters");

my @e;
eval { Params::Lazy->import(doesnotexist => undef) };
push @e, "$@";
eval { Params::Lazy->import(undef() => "^") };
push @e, "$@";

like($_, qr/Both the function name and the/) for @e;

done_testing;
