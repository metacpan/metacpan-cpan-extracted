#!/usr/bin/perl

use strict; use warnings;
use PDF::Create;
use Test::More;

eval { PDF::Create->new->version(1.0) };
like($@, qr//);

eval { PDF::Create->new->version(1.1) };
like($@, qr//);

eval { PDF::Create->new->version(1.2) };
like($@, qr//);

eval { PDF::Create->new->version(1.3) };
like($@, qr//);

eval { PDF::Create->new->version(1.5) };
like($@, qr/Invalid version number/);

done_testing();
