#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::SGML::Raw;

# Input.
my $pyx = <<'END';
(element
-data
)element
END

# Object.
my $obj = PYX::SGML::Raw->new;

# Process.
$obj->parse($pyx);
print "\n";

# Output:
# <element>data</element>