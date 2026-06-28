package PDF::Make::Text::Word;
# Back-compat shim — see PDF::Make::Text for the rename rationale.
use strict;
use warnings;
use PDF::Make::Extract::Word;
our @ISA = ('PDF::Make::Extract::Word');
1;
