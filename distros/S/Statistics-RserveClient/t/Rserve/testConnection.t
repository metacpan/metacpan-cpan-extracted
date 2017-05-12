use Statistics::RserveClient::Connection;

use Test::More tests => 3;

SKIP: {
    eval {
        my $object = Statistics::RserveClient::Connection->new('localhost');
        if ( !ref($object) || !UNIVERSAL::can( $object, 'can' ) ) {
            die "Can't create a connection\n";
        }
    };
    skip "Looks like Rserve is not reachable.  Skipping test.", 2 if $@;

    my $cnx = new_ok(
        'Statistics::RserveClient::Connection' => ['localhost'],
        'new local connection'
    );
    ok( $cnx->initialized(),      'connection is initialized' );
    ok( $cnx->close_connection(), 'closing a connection' );
}

done_testing($number_of_tests);

