#!perl

use strict;
use warnings;

# setup at import time
use Overload::FileCheck '-from-stat' => \&mock_stat_from_sys, qw{:check :stat};

# or set it later at run time
# mock_all_from_stat( \&my_stat );

sub mock_stat_from_sys {

    my ( $stat_or_lstat, $f ) = @_;

    # $stat_or_lstat would be set to 'stat' or 'lstat' depending
    #   if it's a 'stat' or 'lstat' call

    if ( defined $f && $f eq 'mocked.file' ) {    # "<<$f is mocked>>"
        return [                                  # return a fake stat output (regular file)
            64769,      69887159,   33188, 1, 0, 0, 0, 13,
            1539928982, 1539716940, 1539716940,
            4096,       8
        ];

        return stat_as_file();

        return [];                                # if the file is missing
    }

    # let Perl answer the stat question for us
    return FALLBACK_TO_REAL_OP;
}

# ...

# later in your code
if ( -e 'mocked.file' && -f _ && !-d _ ) {
    print "# This file looks real...\n";
}

# ...

# you can unmock the OPs at anytime
Overload::FileCheck::unmock_all_file_checks();
