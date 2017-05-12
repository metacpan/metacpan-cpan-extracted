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
    my $cb  = shift;
    my $res = $cb->( GET "/repo1/info/refs?service=git-upload-pack" );
    is $res->code, 200;
    is $res->header("Content-Type"),
      "application/x-git-upload-pack-advertisement";

    my $body = $res->decoded_content;
    my $first = ( split /\n/, $body )[0];
    is $first,  "001e# service=git-upload-pack";
    like $body, qr/multi_ack_detailed/;
};

done_testing;
