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
      $cb->( GET
"/repo1/objects/pack/pack-4d80b52a389143ec922a6a3f1437c732eaa6ceea.pack"
      );
    is $res->code, 200;
    is $res->header('Content-Type'), 'application/x-git-packed-objects';
};

done_testing
