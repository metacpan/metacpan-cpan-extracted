use strict;
use warnings;
use Test::More;
use Test::Exception;

use Net::Ping;

my $p;

subtest "Verify Net::Ping::new" => sub {
    can_ok 'Net::Ping', 'new';
    $p = new_ok( 'Net::Ping' );
};

diag( "Override Net::Ping::ping now");

# Override Net::Ping::ping so that we don't slow down the rest of the tests...
# localhost and 127.0.0.1 will always pass.
# Other hosts and IPs will fail.
require Mock::Net::Ping;

# Test with the mocked version
subtest "Verify localhost" => sub {
    my ( $ok, $elapsed, $host ) = $p->ping( 'localhost' );
    is( $ok, 1, 'Pinging localhost returns true' );
    is( $host, '127.0.0.1', '$host was returned as 127.0.0.1' );
};

subtest "Verify localhost IP" => sub {
    my ( $ok, $elapsed, $host ) = $p->ping( '127.127.127.127' );
    is( $ok, 1, 'Pinging 127.127.127.127 returns true' );
    is( $host, '127.127.127.127', '$host was returned as 127.127.127.127' );
};

subtest "Verify 10.0.0.0/8 IP" => sub {
    my ( $ok, $elapsed, $host ) = $p->ping( '10.10.10.10' );
    is( $ok, 1, 'Pinging 10.10.10.10 returns true' );
    is( $host, '10.10.10.10', '$host was returned as 10.10.10.10' );
};

subtest "Verify 172.16.0.0/12 IP" => sub {
    my ( $ok, $elapsed, $host ) = $p->ping( '172.16.16.16' );
    is( $ok, 1, 'Pinging 172.16.16.16 returns true' );
    is( $host, '172.16.16.16', '$host was returned as 172.16.16.16' );
};

subtest "Verify 192.168.0.0/16 IP" => sub {
    my ( $ok, $elapsed, $host ) = $p->ping( '192.168.168.168' );
    is( $ok, 1, 'Pinging 192.168.168.168 returns true' );
    is( $host, '192.168.168.168', '$host was returned as 192.168.168.168' );
};

subtest "Verify public IP" => sub {
    my ( $ok, $elapsed, $host ) = $p->ping( '8.8.8.8' ); # Google DNS server
    is( $ok, 0, 'Pinging 8.8.8.8 returns false' );
    is( $host, '8.8.8.8', '$host was returned as 8.8.8.8' );
};

subtest "Verify public hostname" => sub {
    my ( $ok, $elapsed, $host ) = $p->ping( 'www.google.com' );
    is ( $ok, 0, 'Pinging www.google.com returns false' );
    is( $host, 'www.google.com', '$host was returned as www.google.com' );
};

subtest "Verify return in scalar context" => sub {
    my $ok = $p->ping( 'localhost' );
    is( $ok, 1, 'Pinging localhost in scalar context returns true' );
    $ok = $p->ping( '8.8.8.8' );
    is( $ok, 0, 'Pinging 8.8.8.8 in scalar context returns false' );
};

subtest "Verify failures are detected" => sub {
    throws_ok { $p->ping() } qr/Usage: /, 'No parameters passed';
    throws_ok { $p->ping( 'localhost', 1, 2 ) } qr/Usage: /, 'Too many parameters passed';
    throws_ok { $p->ping( 'localhost', 0 ) } qr/Timeout must be greater than 0 seconds/, 'Timeout must be greater than 0 seconds';
    throws_ok { $p->ping( 'localhost', -10 ) } qr/Timeout must be greater than 0 seconds/, 'Timeout must be greater than 0 seconds';
    my $ok = $p->ping( undef );
    is( $ok, undef, 'Undefined $host returns undef' );
};

subtest "Verify elapsed time" => sub {
    $p->hires( 1 ); # enable hires
    diag "hires is $Net::Ping::hires";
    my ( $ok, $elapsed, $host ) = $p->ping( 'localhost' );
    diag "elapsed is $elapsed";
    like( $elapsed * 1000, qr/^\d+\.\d+$/, 'Elapsed time is a float with hires enabled' );
    $p->hires( 0 ); # disable hires
    diag "hires is $Net::Ping::hires";
    ( $ok, $elapsed, $host ) = $p->ping( 'localhost' );
    diag "elapsed is $elapsed";
    like( $elapsed, qr/^\d+$/, 'Elapsed time is an integer with hires disabled' );
};

done_testing;
