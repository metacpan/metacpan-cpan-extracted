#! /usr/bin/env perl

use v5.22;
use warnings;

use Multi::Dispatch;

my $called;
multi report :where({!$called++})  () { say 'first' }
multi report                       () { say 'not first' }

report() for 1..3;


