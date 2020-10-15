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
        'input_tags_item_callback' => sub {
                my $tags_ar = shift;
                print '[ '.$tags_ar->[0].' ]'."\n";
                return;
        },
);

# Process.
$obj->parse($pyx);
print "\n";

# Output:
# [ b ]
# [ d ]
# [ e ]
# <element>data</element>