#!perl
# 
# This file is part of Term-Twiddle-Quiet
# 
# This software is copyright (c) 2010 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 

use strict;
use warnings;

use IO::Interactive qw{ busy };
use Term::Twiddle::Quiet;
use Test::More tests => 1;

# the mock object shouldn't output anything
my $fh = busy {
    my $tw = Term::Twiddle::Quiet->new;
    $tw->start;
    1 for 1 .. 20_000_000;
    $tw->stop;
};

my @lines = <$fh>;
is( scalar(@lines), 0, 'no output' );