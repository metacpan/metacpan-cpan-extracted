#!perl -T

use Test::More tests => 2;

use Pick::TCL;

my $ap = Pick::TCL->new();
$ap->logout();
ok( 1, 'logout() did not croak' );
ok( (not defined($$ap{'_SSH'})), 'no stray Net::OpenSSH objects left behind' );

# diag( "Testing Pick::TCL $Pick::TCL::VERSION, Perl $], $^X" );
