use strict;
use warnings;
no warnings 'once';
$::SUB_QUOTE_NO_HEX_FLOAT = 1;
do './t/quotify.t' or die $@ || $!;
