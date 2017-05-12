#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode;
use Tags::Output::LibXML;

# Object.
my $tags = Tags::Output::LibXML->new(
        'data_callback' => sub {
         my $data_ar = shift;
	 foreach my $data (@{$data_ar}) {
	         $data = encode_utf8($data);
	 }
                return;
 },
);

# Data in characters.
my $data = decode_utf8('řčěšřšč');

# Put data.
$tags->put(
        ['b', 'text'],
 ['d', $data],
 ['e', 'text'],
);

# Print.
print $tags->flush."\n";

# Output:
# <?xml version="1.1" encoding="UTF-8"?>
# <text>řčěšřšč</text>