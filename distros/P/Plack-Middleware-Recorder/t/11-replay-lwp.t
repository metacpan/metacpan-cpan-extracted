use strict;
use warnings;

use lib 't/lib';

use File::Temp;
use Plack::Test;
use Test::More tests => 1;
use Plack::Recorder::TestUtils;

# XXX I really need a better way to create a serialized
#     requests file...

my ( $requests_file, $recorder_app ) = Plack::Recorder::TestUtils->get_app;

test_psgi $recorder_app, sub {
    my ( $cb ) = @_;

    $cb->(GET '/', Host => 'localhost');
};

my $output = qx($^X bin/plack-replay $requests_file t/reply-lwp.psgi -v);
like $output, qr/200 OK/, 'Using LWP::UserAgent to access an external service should succeed';
