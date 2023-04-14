#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use PYX::Hist;

# Error output.
$Error::Pure::TYPE = 'PrintVar';

# Example data.
my $pyx = <<'END';
(begin
(middle
(end
-data
)middle
)begin
END

# PYX::Hist object.
my $obj = PYX::Hist->new;

# Parse.
$obj->parse($pyx);

# Output:
# PYX::Hist: Bad end of element.
# Element: middle