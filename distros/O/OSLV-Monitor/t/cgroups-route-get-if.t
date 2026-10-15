#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use OSLV::Monitor;
use OSLV::Monitor::Backends::cgroups;

if ( $^O ne 'linux' ) {
	plan skip_all => 'not linux';
}

plan tests => 6;

my $base_dir = tempdir( CLEANUP => 1 );
my $obj      = OSLV::Monitor->new( base_dir => $base_dir );
my $backend  = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj );

#
# the args are passed to the shell, so anything not looking like a IP or a
# interface name is refused before ip is run
#

is( $backend->route_get_if( undef,           'docker0' ),    undef, 'a undef IP returns undef' );
is( $backend->route_get_if( '172.17.0.2',    undef ),        undef, 'a undef interface returns undef' );
is( $backend->route_get_if( '172.17.0.2; id', 'docker0' ),   undef, 'a IP with shell characters returns undef' );
is( $backend->route_get_if( '172.17.0.2',    'docker0; id' ), undef, 'a interface with shell characters returns undef' );
is( $backend->route_get_if( '$(id)',         'docker0' ),    undef, 'a IP with a command substitution returns undef' );

# a interface that does not exist makes ip fail
is( $backend->route_get_if( '172.17.0.2', 'oslvtestnope0' ), undef, 'a missing interface returns undef' );
