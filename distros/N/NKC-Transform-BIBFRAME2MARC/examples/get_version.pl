#!/usr/bin/env perl

use strict;
use warnings;

use NKC::Transform::BIBFRAME2MARC;

# Object.
my $obj = NKC::Transform::BIBFRAME2MARC->new;

# Get version.
my $version = $obj->version;

# Print out.
print $version."\n";

# Output:
# 2.6.0