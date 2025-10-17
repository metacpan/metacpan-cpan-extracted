#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$VAR1 = \*{'::$FH'};" >>>
# <<< EXECUTE_SUCCESS: 'HOWDY' >>>
# <<< EXECUTE_SUCCESS: 'DOODY' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OPERATIONS ]]]
open(my filehandleref $FH, '>&STDOUT') or die $OS_ERROR;
print $FH Dumper($FH);
print $FH 'HOWDY', "\n";
print $FH 'DOODY', "\n";
