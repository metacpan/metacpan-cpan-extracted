package PDF::Make::Text::Line;
# Back-compat shim — see PDF::Make::Text for the rename rationale.
use strict;
use warnings;
use PDF::Make::Extract::Line;
our @ISA = ('PDF::Make::Extract::Line');
1;
