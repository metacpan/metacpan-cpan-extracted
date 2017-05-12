# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################
use Test::More tests => 5;

# Load the module
use News::Collabra;
ok(1, 'use News::Collabra worked');

# Create an administrator object
my $admin = new News::Collabra('user', 'pass',
			undef, undef, undef);

isa_ok( $admin, 'News::Collabra' );

# Administrate the server
ok( $admin->server_stop, 'Stopped Collabra news server' );
ok( $admin->server_status, 'Retrieved Collabra news server status' );
ok( $admin->server_start, 'Started Collabra news server' );

1;
