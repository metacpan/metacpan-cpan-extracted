#!/usr/bin/env perl

use strict;
use warnings;

use Tags::Output::Indent;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Object.
my $tags = Tags::Output::Indent->new(
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
# <text>
#   řčěšřšč
# </text>