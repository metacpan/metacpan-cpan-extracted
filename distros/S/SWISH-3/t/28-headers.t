#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

use_ok('SWISH::3::Headers');

ok( my $headers = SWISH::3::Headers->new(), "new Headers" );
ok( my $head = $headers->head( 'foo bar', { url => 'foobar' } ), "->head" );
diag($head);
like( $head, qr/Content-Length: 7/,        "got Content-Length" );
like( $head, qr/Content-Location: foobar/, "got Content-Location" );
