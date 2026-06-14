package main;

use 5.010;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

# If you know Test::File::Verbatim is available you can replace the
# following BEGIN block with 'use Test::File::Verbatim;'.
# As of this writing it is unpublished, but you can get it from
# https://github.com/trwyant/perl-Test-File-Verbatim.git
BEGIN {
    local $@ = undef;
    eval {
	require Test::File::Verbatim;
	Test::File::Verbatim->import();
	1;
    } or plan skip_all => 'Test::File::Verbaim not available';
}

configure_file_verbatim \<<'EOD';
encoding utf-8
trim off
EOD

all_verbatim_ok;

# Use files_are_identical_ok or file_contains_ok for LICENSE

done_testing;

1;

# ex: set textwidth=72 :
