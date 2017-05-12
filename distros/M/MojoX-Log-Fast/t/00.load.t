use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'MojoX::Log::Fast' ) or BAIL_OUT('unable to load module') }

diag( "Testing MojoX::Log::Fast $MojoX::Log::Fast::VERSION, Perl $], $^X" );
