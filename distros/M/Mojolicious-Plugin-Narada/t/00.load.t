use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Mojolicious::Plugin::Narada' ) or BAIL_OUT('unable to load module') }

diag( "Testing Mojolicious::Plugin::Narada $Mojolicious::Plugin::Narada::VERSION, Perl $], $^X" );
