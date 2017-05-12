#!/usr/bin/perl
use strict;
use warnings;
use DateTime;

use POSIX 'strftime';

my @time_formats = (
    q{%A %d %B %Y at %R},
    q{%F %T},
    q{%c},
    q{%A at %R},
    q{%a, %d %b; %R},

    q{%R, %b %d},
    q{%R, %b %d '%y},
    q{%R, %b %d %Y},
);

foreach my $tf (@time_formats) {
    my $dt = DateTime->now();
    print $dt->strftime( $tf ), qq{\n};

    printf(qq{INSERT INTO preference_time_string (time_string, sample) VALUES ('%s', '%s');\n}, $tf, strftime($tf, 0, 15, 18, 13, 6, 106));

    print qq{\n};
}
