use strict;
use warnings;
use Test::More tests => 3;

use_ok 'OpenTracing::GlobalTracer';
use_ok 'OpenTracing::Implementation';
use_ok 'OpenTracing::Implementation::NoOp';
