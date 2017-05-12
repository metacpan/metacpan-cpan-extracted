#!/usr/bin/perl

use strict;
use warnings;

use CPAN::Changes 0.17;

open my $fh, '>', 'Changes.out' or die "Can't open output file Changes.out, $? $! $@";

my $string = CPAN::Changes->load( 'Changes', next_token => qr{{{\$NEXT}}} )->serialize;

print {$fh} $string;

system 'diff', '-Naur', 'Changes', 'Changes.out';

