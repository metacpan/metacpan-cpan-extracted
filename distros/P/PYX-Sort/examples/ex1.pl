#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Sort;

# Example data.
my $pyx = <<'END';
(tag
Aattr1 value
Aattr2 value
Aattr3 value
-text
)tag
END

# PYX::Sort object.
my $obj = PYX::Sort->new;

# Parse.
$obj->parse($pyx);

# Output:
# (tag
# Aattr1="value"
# Aattr2="value"
# Aattr3="value"
# -text
# )tag