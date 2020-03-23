#!/usr/bin/env perl

use strict;
use warnings;

use PYX::Utils qw(decode);

# Text.
my $text = "foo\nbar";

# Decode.
my $decoded_text = decode($text);

# Print to output.
print "Text: $text\n";
print "Decoded text: $decoded_text\n";

# Output:
# Text: foo
# bar
# Decoded text: foo\nbar