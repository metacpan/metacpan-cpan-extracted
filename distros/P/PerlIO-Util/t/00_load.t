#!perl -w
use strict;

use Test::More tests => 7;

require_ok('PerlIO::Util');

require_ok('PerlIO::flock');
require_ok('PerlIO::creat');
require_ok('PerlIO::excl');
require_ok('PerlIO::tee');
require_ok('PerlIO::dir');
require_ok('PerlIO::reverse');
