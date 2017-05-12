#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Utils qw(entity_encode);

# Text.
my $text = 'foo<&"bar';

# Encode entities.
my $encoded_text = entity_encode($text);

# Print to output.
print "Text: $text\n";
print "Encoded text: $encoded_text\n";

# Output:
# Text: foo<&"bar
# Encoded text: foo&lt;&amp;&quot;bar