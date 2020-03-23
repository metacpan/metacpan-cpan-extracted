#!/usr/bin/env perl

use strict;
use warnings;

use PYX::Utils qw(entity_decode);

# Text.
my $text = 'foo&lt;&amp;&quot;bar';

# Decode entities.
my $decoded_text = entity_decode($text);

# Print to output.
print "Text: $text\n";
print "Decoded entities: $decoded_text\n";

# Output:
# Text: foo&lt;&amp;&quot;bar
# Decoded entities: foo<&"bar