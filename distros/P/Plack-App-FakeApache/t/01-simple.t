#
# Plack::Handler::Apache2 is a great example of a mod_perl2 application. This
# shows how to turn it into a Plack application. We are selfhosting!
#


use strict;
use warnings;

use Test::More tests => 1;

use Plack::Test;
use Plack::App::FakeApache;

use HTTP::Request::Common;

my $app = Plack::App::FakeApache->new(
    handler    => 'Plack::Handler::Apache2',
    dir_config => {
        psgi_app => 'examples/simple.psgi',
    }
)->to_app;

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        like $res->content, qr/Hello World/;
    };

