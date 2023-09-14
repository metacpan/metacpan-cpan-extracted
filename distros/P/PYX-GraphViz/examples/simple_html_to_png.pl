#!/usr/bin/env perl

use strict;
use warnings;

use PYX::GraphViz;

# Example PYX data.
my $pyx = <<'END';
(html
(head
(title
-Title
)title
)head
(body
(div
-data
)div
)body
END

# Object.
my $obj = PYX::GraphViz->new;

# Parse.
$obj->parse($pyx);

# Output
# PNG data