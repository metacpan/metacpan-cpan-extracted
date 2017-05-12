use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'MojoX::UserAgent::Throttler' ) or BAIL_OUT('unable to load module') }

diag( "Testing MojoX::UserAgent::Throttler $MojoX::UserAgent::Throttler::VERSION, Perl $], $^X" );
