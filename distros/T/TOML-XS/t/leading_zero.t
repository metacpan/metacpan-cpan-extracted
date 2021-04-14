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
    like( $err, qr</badbad>, 'error indicates JSON pointer' );
    like( $err, qr<json pointer>i, '… and we tell them it’s a JSON pointer' );
}

$doc = <<END;
badbad = [ { "/fo~/é" = [00000] } ]
END

{
    eval { TOML::XS::from_toml($doc)->to_struct() };
    my $err          = $@;
    diag $err;
    like( $err, qr</badbad/0/~1fo~0~1\x{e9}/0>, 'error indicates deep, escaped, decoded JSON pointer' );
}

done_testing;
