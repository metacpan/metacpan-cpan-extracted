#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Dumpvalue;
use Tags::Utils qw(encode_attr_entities);

# Input data.
my @data = ('&', '<', '"');

# Encode.
encode_attr_entities(\@data);

# Dump out.
my $dump = Dumpvalue->new;
$dump->dumpValues(\@data);

# Output:
# 0  ARRAY(0x8b8f428)
#    0  '&amp;'
#    1  '&lt;'
#    2  '&quot;'