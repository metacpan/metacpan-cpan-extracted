#!/usr/bin/env perl
# t/32_same_arity.pl: invoked by t/32_same_arity.t
{
    package main::oops;
    use Sub::Multi::Tiny qw($foo);
    sub first :M($foo) { return $foo+1; }
    sub second :M($foo) { return $foo+2; }
}
