#!perl -wT

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Template::Provider::CustomDBIC' );

diag( 'Testing Template::Provider::CustomDBIC '
            . $Template::Provider::CustomDBIC::VERSION );
