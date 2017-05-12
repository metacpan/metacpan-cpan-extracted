#!perl -T

use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok('MooX::Types::MooseLike::DateTime') }
require_ok('MooX::Types::MooseLike::DateTime');
