#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$VAR1 = 'MYFH';" >>>
# <<< EXECUTE_SUCCESS: 'HOWDY' >>>
# <<< EXECUTE_SUCCESS: 'DOODY' >>>
# <<< EXECUTE_SUCCESS: 'DANDY' >>>

# [[[ HEADER ]]]
# use strict;  # disable to avoid the error... Can't use string ("MYFH") as a symbol ref while "strict refs" in use
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OPERATIONS ]]]
my filehandle $FH = 'MYFH';
open($FH, '>&STDOUT') or die $OS_ERROR;
print $FH Dumper($FH);
print $FH  'HOWDY', "\n";
print MYFH 'DOODY', "\n";
print MYFH 'DANDY', "\n";  # include to avoid the warning... Name "main::MYFH" used only once: possible typo
