#!/usr/bin/env perl

use strict;
use warnings;

use PYX::SGML::Tags;
use Tags::Output::Indent;

# Input.
my $pyx = <<'END';
(element
-data
)element
END

# Object.
my $obj = PYX::SGML::Tags->new(
        'tags' => Tags::Output::Indent->new(
                'output_handler' => \*STDOUT,
        ),
);

# Process.
$obj->parse($pyx);
print "\n";

# Output:
# <element>data</element>