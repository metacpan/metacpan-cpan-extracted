use strict;
use warnings;

use Test::More;

use Plack::Test;
use Plack::App::FakeApache;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use HTTP::Request::Common;

my $app = Plack::App::FakeApache->new(
    handler    => 'DumbHandler2',
    dir_config => {},
    request_class => 'TestRequest',
)->to_app;

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        like $res->content, qr/HelloWorld/;
    };

done_testing;
