use 5.006;
use lib::relative '.';
use Kit;

# Simple recursion, where each candidate dispatches to a specific
# other candidate.
{
    package main::fib;
    use Sub::Multi::Tiny qw(D:TypeParams $n);
    sub base  :M($n where { $_ <= 1 })  { 1 }
    sub other :M($n)                    { $n * fib($n-1) }

}

ok do { no strict 'refs'; defined *{"main::fib"}{CODE} }, 'fib() exists';
ok do { no strict 'refs'; !defined *{"main::nonexistent"}{CODE} }, 'sanity check';

cmp_ok fib(0), '==', 1, here;
cmp_ok fib(1), '==', 1, here;
cmp_ok fib(2), '==', 2, here;
cmp_ok fib(3), '==', 6, here;
cmp_ok fib(5), '==', 120, here;

done_testing;
