#!/usr/bin/perl

use strict;
use warnings;

use Number::Continuation qw(continuation);

if ($ARGV[0]) {
    my $contin = continuation(shift);
    print $contin, "\n";
} else {
    print "Usage: $0 'numbers'\n";
    exit;
}
