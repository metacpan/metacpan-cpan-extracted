#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;

# t/34_invalid_param.pl: Invoked by t/34_invalid_param.t
{
    package main::oops;
    use Sub::Multi::Tiny qw($foo);
    sub first :M($foo) { return $foo+1; }
    sub second :M($foo, $bar) { return $foo+2; }    # invalid signature
}
