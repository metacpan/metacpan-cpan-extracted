use strict;
use Test::More;

use File::Which qw(which);
plan skip_all => 'could not find git' unless which('git');

use File::Path qw(remove_tree);
use File::Copy::Recursive qw(rcopy);

use Plack::Test;
use HTTP::Request::Common;
use Plack::App::GitSmartHttp;

$Plack::Test::Impl = "Server";

my $app = Plack::App::GitSmartHttp->new(
    root          => "t/test_repos",
    upload_pack   => 1,
    received_pack => 1,
);

rcopy( "t/test_repos/repo1", "t/test_repos/repo2" );

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(
        POST "/repo2/git-receive-pack",
        "Content-Type" => "application/x-git-receive-pack-request",
        "Content" =>
"00810000000000000000000000000000000000000000 6410316f2ed260666a8a6b9a223ad3c95d7abaed refs/tags/v1.0. report-status side-band-64k0000",
    );
    is $res->code, 200;
    is $res->header("Content-Type"), 'application/x-git-receive-pack-result';
};

remove_tree("t/test_repos/repo2");

done_testing
