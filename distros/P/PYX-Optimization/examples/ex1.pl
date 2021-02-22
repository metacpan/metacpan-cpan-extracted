#!/usr/bin/env perl

use strict;
use warnings;

use PYX::Optimization;

# Content.
my $pyx_to_optimize = <<'END';
(element
- data \n data
)element
_       comment
(element
-                                 \n foo
)element
END

PYX::Optimization->new->parse($pyx_to_optimize);

# Output:
# (element
# -data data
# )element
# _comment
# (element
# -foo
# )element