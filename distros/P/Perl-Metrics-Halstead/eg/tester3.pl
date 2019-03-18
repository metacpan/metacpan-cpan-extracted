#!/usr/bin/env perl
use strict;
use warnings;

hello(1);
hello(0);

sub hello {
    my $flag = shift;
    print $flag ? 'Hello' : 'Goodbye', " world!\n";
}
