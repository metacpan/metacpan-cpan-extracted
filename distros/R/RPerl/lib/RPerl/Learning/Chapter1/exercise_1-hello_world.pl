#!/usr/bin/env perl

# Learning RPerl, Chapter 1, Exercise 1
# Print "Hello, World!"; the classic first program for new programmers

# [[[ HEADER ]]]
use RPerl;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ OPERATIONS ]]]
print 'Hello, World!', "\n";
