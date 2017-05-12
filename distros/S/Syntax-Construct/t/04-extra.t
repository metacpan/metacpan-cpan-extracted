#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 1;
use Syntax::Construct ();

SKIP: {
    $] lt '5.020' or skip '5.018 or older needed', 1;

    my $string = 'a';
    eval "use utf8; \$string =~ s\N{U+2759}a\N{U+2759}\N{U+2759}b\N{U+2759}";
    is($string, 'b', 's-utf8-delimiters-hack');
}

done_testing();
