#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 4;


ok(! eval << '__CODE__', 'no_params');
    use Syntax::Construct; 1;
__CODE__

like($@, qr/Empty construct list /, 'no_params exception');


ok(! eval << '__CODE__', 'unknown');
    use Syntax::Construct qw( a ) ; 1;
__CODE__

like ($@, qr/Unknown construct `a' /, 'unknown exception');
