use strict;
use warnings;

use Test::More;
use Test::Deep;
use File::Temp qw(tmpnam);
use File::Basename;
use Data::Dumper;

my $tmpnam = basename tmpnam;

BEGIN {
    use_ok('Net::Hadoop::WebHDFS::LWP');
}
require_ok('Net::Hadoop::WebHDFS::LWP');

my ( $WEBHDFS_HOST, $WEBHDFS_PORT, $WEBHDFS_USER )
    = @ENV{qw(WEBHDFS_HOST WEBHDFS_PORT WEBHDFS_USER)};

SKIP: {
    skip 'WEBHDFS_HOST must be defined in environment', 4
        if !$WEBHDFS_HOST;

    ok( my $client = Net::Hadoop::WebHDFS::LWP->new(
            host        => $WEBHDFS_HOST,
            port        => $WEBHDFS_PORT || 14000,
            username    => $WEBHDFS_USER || "johndoe",
            httpfs_mode => 1,
        ),
        "create a client",
    );
    ok( $client->create(
            '/tmp/Net-Hadoop-WebHDFS-LWP-test-' . $tmpnam,
            "this is a test",    # content
            permission => '644',
            overwrite  => 'true'
        ),
        "write a file in /tmp"
    );
    ok( do {
            my $file;
            $file = $client->stat( '/tmp/Net-Hadoop-WebHDFS-LWP-test-' . $tmpnam );
            $file->{replication} > 0;
        },
        "get file info",
    );
    ok( $client->delete(
            '/tmp/Net-Hadoop-WebHDFS-LWP-test-' . $tmpnam,
        ),
        "delete the file"
    );
}

done_testing;

