use strict;
use warnings;

use Test::More;
use Path::Class;

use Plack::App::Proxy::Selective;


subtest 'test for match_uri' => sub {
    my $env = +{
        REQUEST_URI => 'http://google.com/script/hoge.js',
        HTTP_HOST => 'google.com',
    };
    my $filename = 'hoge.js';

    my $source_dir = 'script';
    is(Plack::App::Proxy::Selective::match_uri($env, $source_dir), $filename);

    $source_dir = '/script';
    is(Plack::App::Proxy::Selective::match_uri($env, $source_dir), $filename);

    $source_dir = '/script/';
    is(Plack::App::Proxy::Selective::match_uri($env, $source_dir), $filename);

    done_testing;
};

subtest 'test for match_uri with multiple suffixes' => sub {
    my $env = +{
        REQUEST_URI => 'http://google.com/script/hoge.user.js',
        HTTP_HOST => 'google.com',
    };
    my $source_dir = 'script';
    is(Plack::App::Proxy::Selective::match_uri($env, $source_dir), 'hoge.user.js');

    done_testing;
};

subtest 'test for match_uri with greedy regex' => sub {
    my $env = +{
        REQUEST_URI => 'http://google.com/script/hoge.js',
        HTTP_HOST => 'google.com',
    };
    my $source_dir = 'script.*';
    is(Plack::App::Proxy::Selective::match_uri($env, $source_dir), 'hoge.js');

    done_testing;
};

subtest 'test for server_local' => sub {
    my $base_dir = file(__FILE__)->dir;
    my $dir1 = Plack::App::Proxy::Selective::server_local($base_dir, '/script');
    my $dir2 = Plack::App::Proxy::Selective::server_local($base_dir, 'script');
    my $dir3 = Plack::App::Proxy::Selective::server_local($base_dir, 'script/');

    is($dir1->root, $dir2->root);
    is($dir2->root, $dir3->root);
    is($dir3->root, $dir1->root);

    done_testing;
};

done_testing;
