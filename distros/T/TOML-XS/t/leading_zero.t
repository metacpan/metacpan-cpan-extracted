#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Config;

use TOML::XS;

my $doc = <<END;
badbad = 00000
END

{
    eval { TOML::XS::from_toml($doc)->to_struct() };
    my $err          = $@;
    diag $err;
    like( $err, qr<leading 0>, 'error indicates leading 0' );
}

$doc = <<END;
badbad = [ { "/fo~/é" = [00000] } ]
END

{
    eval { TOML::XS::from_toml($doc)->to_struct() };
    my $err          = $@;
    diag $err;
    like( $err, qr<leading 0>, 'error indicates leading 0' );
}

done_testing;
