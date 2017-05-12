use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Mojolicious::Plugin::SecureCORS' ) or BAIL_OUT('unable to load module') }

diag( "Testing Mojolicious::Plugin::SecureCORS $Mojolicious::Plugin::SecureCORS::VERSION, Perl $], $^X" );
