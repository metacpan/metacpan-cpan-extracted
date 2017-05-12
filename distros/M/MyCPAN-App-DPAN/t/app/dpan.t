use strict;
use warnings;

use Test::More tests => 2;

BEGIN { $INC{'Log/Log4perl.pm'} = 1; package Log::Log4perl; sub AUTOLOAD { __PACKAGE__ }; }

my $class = 'MyCPAN::App::DPAN';
use_ok( $class );

can_ok( $class, 'activate' );
