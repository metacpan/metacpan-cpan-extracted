#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'No such class filehandlere' >>>
# <<< EXECUTE_ERROR: 'Global symbol "$FH" requires explicit package name' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OPERATIONS ]]]
open(my filehandlere $FH, '>&STDOUT') or die $OS_ERROR;
print $FH Dumper($FH);
print $FH 'HOWDY', "\n";
print $FH 'DOODY', "\n";
