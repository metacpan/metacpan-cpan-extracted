use Test::More tests => 1;
use lib qw(lib);

BEGIN {
use_ok( 'MooseX::Workers' );
}

my $ver = $MooseX::Workers::VERSION || '__UNRELEASED__';

diag( "Testing MooseX::Workers $ver" );
