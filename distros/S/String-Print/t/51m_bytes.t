#!/usr/bin/env perl
# Test BYTES modifier

use warnings;
use strict;
use utf8;

use Test::More;

use String::Print;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

sub fill($$)
{   my ($expected, $count) = @_;
    my $show = $f->sprinti("{a BYTES}", a => $count);
	$show =~ s/\,/./g;  # depends on effective locale

    is $show, $expected, $expected;
}

use constant KB => 1024;

fill '  0 B', 0;

### no fraction
fill '  1 B', 1;
fill ' 10 B', 10;
fill '100 B', 100;
fill '999 B', 999;

### numeric resolution
fill '1.0kB', 1000;
fill '1.0kB',    1 * KB;
fill '1.5kB',  1.5 * KB;
fill '1.7kB', 1.66 * KB;  # 0.05 is 1/20 of 1024, not 1000
fill '9.9kB', 9.94 * KB;
fill ' 10kB', 9.95 * KB;
fill '999kB',  999 * KB;

### large numbers
fill '1.5MB',  1.5 * KB * KB;
fill ' 11MB', 10.6 * KB * KB;

fill '1.5GB',  1.5 * KB * KB * KB;
fill ' 11GB', 10.6 * KB * KB * KB;

fill '1.5TB',  1.5 * KB * KB * KB * KB;
fill ' 11TB', 10.6 * KB * KB * KB * KB;

### out of range
fill '84703ZB', 10e25;

done_testing;
