#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
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