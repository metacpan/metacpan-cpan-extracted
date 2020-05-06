#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 1;

if($ENV{AUTOMATED_TESTING})
{   if(open my $index, '<:encoding(utf8)', 'constindex.txt')
    {   undef $\;
        diag <$index>;
        close $index;
    }
}

ok(1);
