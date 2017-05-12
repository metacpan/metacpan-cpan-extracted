use strict;
use Test::More 0.98;
use Plack::Test;
use autodie;

use Data::Dumper;
use File::Spec ();
use File::Temp ();
use HTTP::Request::Common;
use Net::PhotoBackup::Server;

my $test_dir    = File::Temp::tempdir( CLEANUP => 1 );
my $config_file = File::Spec->catfile( $test_dir, '.photobackup' );
my $pid         = File::Spec->catfile( $test_dir, '.photobackup.pid' );
my $media_root  = File::Spec->catdir( $test_dir, 'photobackup' );
mkdir $media_root;

open my $fh, '>', $config_file;
print $fh qq{
# Settings for Net::PhotoBackup::Server - perldoc Net::PhotoBackup::Server
[photobackup]
MediaRoot=$media_root
Password=ae1413078f26b37974431e7c1d973da2d1fab1d5839707823ba800bafdf746dfaeb9bf29b4aba3a3c3108e8d712aceb7048b4a007b521bf9aff127621374a5b3
Port=58420
};
close $fh;

my $server = Net::PhotoBackup::Server->new( config_file => $config_file, pid => $pid, env => 'deployment', daemonize => 0 );
my $app = $server->app;
my $handle = Plack::Test->create($app);

my $response = $handle->request(GET '/');
is( $response->code, 301, "Server is responding to GET /" ) 
    or diag( "Diagnostics for 'Server is responding to GET /'" => Dumper $response);
is( $response->header('location'), 'https://photobackup.github.io/', "GET / redirects to https://photobackup.github.io/" );

$response = $handle->request( POST '/test', {} );
is( $response->code, 403, "POST /test without password fails" )
    or diag( "Diagnostics for 'POST /test without password fails'" => Dumper $response);

$response = $handle->request( POST '/test', { password => 'WRONG' } );
is( $response->code, 403, "POST /test with incorrect password fails" )
    or diag( "Diagnostics for 'POST /test with incorrect password fails'" => Dumper $response);

$response = $handle->request( POST '/test', { password => 'ae1413078f26b37974431e7c1d973da2d1fab1d5839707823ba800bafdf746dfaeb9bf29b4aba3a3c3108e8d712aceb7048b4a007b521bf9aff127621374a5b3' } );
ok( $response->is_success, "POST /test with correct password succeeds" )
    or diag( "Diagnostics for 'POST /test with correct password succeeds'" => Dumper $response);


done_testing;

exit;
