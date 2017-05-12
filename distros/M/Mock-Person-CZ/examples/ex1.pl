#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(encode_utf8);
use Mock::Person::CZ qw(name);

# Error.
print encode_utf8(name())."\n";

# Output like.
# Štefan Lukáš Šimek