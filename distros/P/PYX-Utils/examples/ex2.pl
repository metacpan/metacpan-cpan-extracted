#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Utils qw(encode);

# Text.
my $text = 'foo\nbar';

# Encode text.
my $encoded_text = encode($text);

# Print to output.
print "Text: $text\n";
print "Encoded text: $encoded_text\n";

# Output:
# Text: foo\nbar
# Encoded text: foo
# bar