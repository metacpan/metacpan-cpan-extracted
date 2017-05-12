use strict;
use Test::More;

use File::Which qw(which);
plan skip_all => 'could not find git' unless which('git');

use Plack::Request;
use Plack::App::GitSmartHttp;

subtest 'git-upload-pack' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'POST',
            REQUEST_URI    => '/base/foo/git-upload-pack',
            PATH_INFO      => '/base/foo/git-upload-pack',
            QUERY_STRING   => 'service=git-upload-pack'
        }
    );
    is( $gsh->get_service($req), 'upload-pack' );
};

subtest 'git-receive-pack' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'POST',
            REQUEST_URI    => '/base/foo/git-receive-pack',
            PATH_INFO      => '/base/foo/git-receive-pack',
            QUERY_STRING   => 'service=git-receive-pack'
        }
    );
    is( $gsh->get_service($req), 'receive-pack' );
};

subtest 'git-upload-pack invalid param' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'POST',
            REQUEST_URI    => '/base/foo/git-upload-pack',
            PATH_INFO      => '/base/foo/git-upload-pack',
            QUERY_STRING   => 'service=bar-upload-pack'
        }
    );
    is( $gsh->get_service($req), undef );
};

subtest 'git-receive-pack invalid param' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'POST',
            REQUEST_URI    => '/base/foo/git-receive-pack',
            PATH_INFO      => '/base/foo/git-receive-pack',
            QUERY_STRING   => 'service=foo-receive-pack'
        }
    );
    is( $gsh->get_service($req), undef );
};

done_testing;
