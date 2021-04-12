#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Config;

use TOML::XS;

my $doc = <<END;
# This is a TOML document

bad = "Triple-single quote like this ''' is forbidden."
END

{
    eval { TOML::XS::from_toml($doc) };
    my $err          = $@;
    diag $err;
    like( $err, qr<quote>,           'reject triple-quote in the TOML string' );
}

done_testing;
