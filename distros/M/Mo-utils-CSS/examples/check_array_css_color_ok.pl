#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::CSS qw(check_array_css_color);

my $self = {
        'key' => [
                'red',
                '#F00', '#FF0000', '#FF000000',
                'rgb(255,0,0)', 'rgba(255,0,0,0.3)',
                'hsl(120, 100%, 50%)', 'hsla(120, 100%, 50%, 0.3)',
        ],
};
check_array_css_color($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok