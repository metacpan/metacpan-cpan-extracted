#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use IO::Barf qw(barf);
use SGML::PYX;

# Input file.
my (undef, $input_file) = tempfile();
my $input = <<'END';
<html><head><title>Foo</title></head><body><div /></body></html>
END
barf($input_file, $input);

# Object.
my $obj = SGML::PYX->new;

# Parse file.
$obj->parsefile($input_file);

# Output:
# (html
# (head
# (title
# -Foo
# )title
# )head
# (body
# (div
# )div
# )body
# )html
# -\n