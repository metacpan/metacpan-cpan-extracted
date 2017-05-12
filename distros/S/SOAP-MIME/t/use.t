#!/usr/bin/perl -w

use strict;

use Test;

BEGIN { plan tests => 2 }

use SOAP::Lite; ok(1);
use SOAP::MIME; ok(1);

exit;
