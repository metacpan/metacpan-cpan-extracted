#!perl -wT

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Template::Provider::DBIC' );

diag( 'Testing Template::Provider::DBIC '
            . $Template::Provider::DBIC::VERSION );
