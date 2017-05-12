#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Utils qw(encode_newline);

# Input text.
my $text = <<'END';
foo
bar
END

# Encode newlines.
my $out = encode_newline($text);

# Print out.
print $out."\n";

# Output:
# foo\nbar\n