#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(encode_utf8);
use Mock::Person::EN qw(name);

# Set output name to three names.
$Mock::Person::EN::TYPE = 'three';

# Error.
print encode_utf8(name())."\n";

# Output like.
# Jack Ryan Hatheway