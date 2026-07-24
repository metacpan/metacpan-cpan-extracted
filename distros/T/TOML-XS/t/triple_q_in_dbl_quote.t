#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Config;

use TOML::XS;

my $toml = <<END;
# This is a TOML document

wasbad = "Triple-single quote like this ''' is not forbidden."
END

my $doc = TOML::XS::from_toml($toml);

cmp_deeply(
    $doc->to_struct(),
    {
        wasbad => "Triple-single quote like this ''' is not forbidden.",
    },
);

done_testing;
