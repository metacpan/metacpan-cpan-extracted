#! perl

use strict;
use warnings;
use Test::More;

use lib qw(lib t/lib);

use Test::App;

my $app = Test::App->new();

ok( $app, 'Got a Test App' );

SKIP: {
    skip 'Need FASTLY_API_KEY and FASTLY_SERVICE_ID', 3
        unless $ENV{FASTLY_API_KEY};

    my $purged = $app->cdn_purge_now(
        {   keys       => [ 'should_never', 'ever_exist' ],
            soft_purge => 1,
        }
    );
    ok( $purged, "Purge seems to have succeded" );

}

done_testing();
