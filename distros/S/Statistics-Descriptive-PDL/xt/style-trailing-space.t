#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::TrailingSpace";
if ($@)
{
    plan skip_all => "Test::TrailingSpace required for trailing space test.";
}
else
{
    plan tests => 1;
}

my $finder = Test::TrailingSpace->new(
    {
        root => '.',
        filename_regex => qr/(?:(?:\.(?:t|pm|pl|PL|yml|json|arc|vim))|README|Changes|LICENSE|MANIFEST)\z/,
    },
);

# TEST
$finder->no_trailing_space(
    "No trailing space was found."
);

