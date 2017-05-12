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
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd,     'service_rpc' );
    is( $path,    '/base/foo' );
    is( $reqfile, 'git-upload-pack' );
};

subtest 'git-upload-pack not_allowed' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'GET',
            REQUEST_URI    => '/base/foo/git-upload-pack',
            PATH_INFO      => '/base/foo/git-upload-pack',
            QUERY_STRING   => '',
            SERVER_NAME    => '',
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd, 'not_allowed' );
};

subtest 'get_info_refs' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'GET',
            REQUEST_URI    => '/base/foo/info/refs',
            PATH_INFO      => '/base/foo/info/refs',
            QUERY_STRING   => '',
            SERVER_NAME    => '',
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd,     'get_info_refs' );
    is( $path,    '/base/foo' );
    is( $reqfile, 'info/refs' );
};

subtest 'get_text_file' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'GET',
            REQUEST_URI    => '/base/foo/HEAD',
            PATH_INFO      => '/base/foo/HEAD',
            QUERY_STRING   => '',
            SERVER_NAME    => '',
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd,     'get_text_file' );
    is( $path,    '/base/foo' );
    is( $reqfile, 'HEAD' );
};

subtest 'get_text_file info/alternates' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'GET',
            REQUEST_URI    => '/base/foo/objects/info/alternates',
            PATH_INFO      => '/base/foo/objects/info/alternates',
            QUERY_STRING   => '',
            SERVER_NAME    => '',
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd,     'get_text_file' );
    is( $path,    '/base/foo' );
    is( $reqfile, 'objects/info/alternates' );
};

subtest 'get_text_file info/http-alternates' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'GET',
            REQUEST_URI    => '/base/foo/objects/info/http-alternates',
            PATH_INFO      => '/base/foo/objects/info/http-alternates',
            QUERY_STRING   => '',
            SERVER_NAME    => '',
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd,     'get_text_file' );
    is( $path,    '/base/foo' );
    is( $reqfile, 'objects/info/http-alternates' );
};

subtest 'get_info_packs' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'GET',
            REQUEST_URI    => '/base/foo/objects/info/packs',
            PATH_INFO      => '/base/foo/objects/info/packs',
            QUERY_STRING   => '',
            SERVER_NAME    => '',
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd,     'get_info_packs' );
    is( $path,    '/base/foo' );
    is( $reqfile, 'objects/info/packs' );
};

subtest 'get_loose_object' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'GET',
            REQUEST_URI =>
              '/base/foo/objects/3b/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccc',
            PATH_INFO =>
              '/base/foo/objects/3b/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccc',
            QUERY_STRING => '',
            SERVER_NAME  => '',
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd,     'get_loose_object' );
    is( $path,    '/base/foo' );
    is( $reqfile, 'objects/3b/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccc' );
};

subtest 'get_pack_file' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'GET',
            REQUEST_URI =>
'/base/foo/objects/pack/pack-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb.pack',
            PATH_INFO =>
'/base/foo/objects/pack/pack-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb.pack',
            QUERY_STRING => '',
            SERVER_NAME  => '',
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd,  'get_pack_file' );
    is( $path, '/base/foo' );
    is( $reqfile,
        'objects/pack/pack-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb.pack' );
};

subtest 'get_idx_file' => sub {
    my $gsh = Plack::App::GitSmartHttp->new;
    my $req = Plack::Request->new(
        {
            REQUEST_METHOD => 'GET',
            REQUEST_URI =>
'/base/foo/objects/pack/pack-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb.idx',
            PATH_INFO =>
'/base/foo/objects/pack/pack-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb.idx',
            QUERY_STRING => '',
            SERVER_NAME  => '',
        }
    );
    my ( $cmd, $path, $reqfile, $rpc ) = $gsh->match_routing($req);
    is( $cmd,  'get_idx_file' );
    is( $path, '/base/foo' );
    is( $reqfile,
        'objects/pack/pack-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb.idx' );
};

done_testing;
