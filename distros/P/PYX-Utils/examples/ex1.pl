#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
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