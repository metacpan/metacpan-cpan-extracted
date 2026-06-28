package PDF::Make::Text::Result;
# Back-compat shim — see PDF::Make::Text for the rename rationale.
use strict;
use warnings;
use PDF::Make::Extract::Result;
our @ISA = ('PDF::Make::Extract::Result');
1;
