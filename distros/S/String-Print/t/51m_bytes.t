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

fill '  0  B', 0;

### no fraction
fill '  1  B', 1;
fill ' 10  B', 10;
fill '100  B', 100;
fill '999  B', 999;

### numeric resolution
fill '1.0 kB', 1000;
fill '1.0 kB',    1 * KB;
fill '1.5 kB',  1.5 * KB;
fill '1.7 kB', 1.66 * KB;  # 0.05 is 1/20 of 1024, not 1000
fill '9.9 kB', 9.94 * KB;
fill ' 10 kB', 9.95 * KB;
fill '999 kB',  999 * KB;

### large numbers
fill '1.5 MB',  1.5 * KB * KB;
fill ' 11 MB', 10.6 * KB * KB;

fill '1.5 GB',  1.5 * KB * KB * KB;
fill ' 11 GB', 10.6 * KB * KB * KB;

fill '1.5 TB',  1.5 * KB * KB * KB * KB;
fill ' 11 TB', 10.6 * KB * KB * KB * KB;

### out of range
fill '84703 ZB', 10e25;

done_testing;
