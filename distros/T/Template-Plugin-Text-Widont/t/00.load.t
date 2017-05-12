#!perl -wT

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Template::Plugin::Text::Widont' );

diag( 'Testing Template::Plugin::Text::Widont'
            . $Template::Plugin::Text::Widont::VERSION );
