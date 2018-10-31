#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use File::Slurper qw(read_text);
use Test::More 0.96;
require "testlib.pl";

# Perl versions < 5.14 don't work with today's UTF-8-based locales,
# leading to a wrong parse result.  So skip the test for old Perls:
if ($] > 5.012) {
    test_to_html(
        name => 'example.org',
        args => {
            source_file=>"$Bin/data/example.org",
            html_title => 'Example',
            css_url => 'style.css',
        },
        status => 200,
        result => scalar read_text("$Bin/data/example.org.html"),
    );
}

test_to_html(
    name => 'example.org',
    args => {
        source_file=>"$Bin/data/naked.org",
        naked=>1,
    },
    status => 200,
    result => scalar read_text("$Bin/data/naked.org.html"),
);

done_testing();
