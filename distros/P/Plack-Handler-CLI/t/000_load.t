#!perl -w

use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Plack::Handler::CLI' }

diag "Testing Plack::Handler::CLI/$Plack::Handler::CLI::VERSION";
