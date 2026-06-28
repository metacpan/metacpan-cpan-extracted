package PDF::Make::Text::Block;
# Back-compat shim — see PDF::Make::Text for the rename rationale.
use strict;
use warnings;
use PDF::Make::Extract::Block;
our @ISA = ('PDF::Make::Extract::Block');
1;
