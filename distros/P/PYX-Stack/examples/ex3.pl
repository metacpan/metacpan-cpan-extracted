#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure;
use PYX::Stack;

# Error output.
$Error::Pure::TYPE = 'PrintVar';

# Example data.
my $pyx = <<'END';
(begin
(middle
-data
)end
)middle
)begin
END

# PYX::Stack object.
my $obj = PYX::Stack->new(
        'bad_end' => 1,
);

# Parse.
$obj->parse($pyx);

# Output:
# PYX::Stack: Bad end of element.
# Element: end