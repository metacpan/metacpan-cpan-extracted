#!perl

use strict;
use warnings;

use Proc::Topus qw( spawn );
use Test::More;


eval { spawn( undef ) };
like( $@, qr/^Single arguments must be a HASH ref\b/, 'single argument' );

eval { spawn( 'fail' ) };
like( $@, qr/^Single arguments must be a HASH ref\b/, 'single argument' );

eval { spawn( undef, undef, undef ) };
like( $@, qr/^Odd number of arguments\b/, 'odd arguments' );

eval { spawn() };
like( $@, qr/^No workers defined\b/, 'no workers' );

eval { spawn( workers => { } ) };
like( $@, qr/^No workers defined\b/, 'no workers' );

eval { spawn( workers => { fail => { } } ) };
like( $@, qr/^Invalid worker count \(fail\)/, 'worker count' );

eval { spawn( workers => { fail => { count => -1 } } ) };
like( $@, qr/^Invalid worker count \(fail\)/, 'worker count' );

eval { spawn( workers => { fail => { count => 1, conduit => 'fail' } } ) };
like( $@, qr/^Invalid worker conduit 'fail' for worker 'fail'/, 'invalid conduit' );

eval { spawn( workers => { fail => { count => 1, loader => sub { exit 1 } } } ) };
like( $@, qr/^One or more loaders failed\b/, 'loader' );


done_testing;
