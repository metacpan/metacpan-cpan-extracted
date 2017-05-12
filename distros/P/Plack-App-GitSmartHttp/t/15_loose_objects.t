use strict;
use Test::More;

use File::Which qw(which);
plan skip_all => 'could not find git' unless which('git');

use Plack::Test;
use HTTP::Request::Common;
use Plack::App::GitSmartHttp;

my $app = Plack::App::GitSmartHttp->new(
    root          => "t/test_repos",
    upload_pack   => 1,
    received_pack => 1,
);

test_psgi $app, sub {
    my $cb = shift;
    my $res =
      $cb->( GET "/repo1/objects/80/5c96a6ed4f2b3d61bab765596220f31e80d3ba" );
    is $res->code, 200;
    is $res->header('Content-Type'), 'application/x-git-loose-object';
};

done_testing
