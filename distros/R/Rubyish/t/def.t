#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;
use 5.010;

use Rubyish::Syntax::def;

def sum {
    return 0 unless defined $self;
    diag $self;
    return $self + sum(@_);
}

;

is 3, sum(1,2);
