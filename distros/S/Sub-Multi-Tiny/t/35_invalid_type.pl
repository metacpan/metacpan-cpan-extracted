#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;

# t/35_invalid_type.pl: Invoked by t/35_invalid_type.t
{
    package main::oops;
    use Sub::Multi::Tiny qw($foo);
    use Types::Standard qw(Int);
    sub first :M(Int $foo) { return $foo+1; }
}
