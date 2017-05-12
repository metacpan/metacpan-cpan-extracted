#!perl -wT

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Template::Provider::PerContextDBIC' );

diag( 'Testing Template::Provider::PerContextDBIC '
            . $Template::Provider::PerContextDBIC::VERSION );
