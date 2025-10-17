#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'Name "main::FH" used only once: possible typo' >>>
# <<< EXECUTE_ERROR: 'print() on unopened filehandle FH' >>>
# <<< EXECUTE_ERROR: 'Die on purpose so warnings can be tested' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OPERATIONS ]]]
open(my filehandleref $FH, '>&STDOUT') or die $OS_ERROR;
print $FH Dumper($FH);
print FH 'HOWDY', "\n";
print $FH 'DOODY', "\n";
die 'Die on purpose so warnings can be tested';
