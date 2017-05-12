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
    my $res = $cb->( GET "/repo1/info/refs?service=git-receive-pack" );
    is $res->code, 200;
    is $res->header("Content-Type"),
      "application/x-git-receive-pack-advertisement";

    my $body = $res->decoded_content;
    my $first = ( split /\n/, $body )[0];
    is $first,  "001f# service=git-receive-pack";
    like $body, qr/report-status/;
    like $body, qr/delete-refs/;
    like $body, qr/ofs-delta/;
};

done_testing;
