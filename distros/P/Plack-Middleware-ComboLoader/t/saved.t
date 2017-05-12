use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use URI::Escape 'uri_escape';

use_ok('Plack::Middleware::ComboLoader');

my $escaped = uri_escape('foo.js&bar.js');
my $loader = Plack::Middleware::ComboLoader->new({
    roots => {
        't1' => 't/static/js',
    },
    save => 't/static/generated'
});

$loader->wrap( sub {
    [ 200, [ 'Content-Type' => 'text/plain' ], [ 'app' ] ]
});

test_psgi $loader => sub {
    my $server = shift;
    subtest "transforming" => sub {
        my $res = $server->(GET '/t1?foo.js&bar.js');
        ok($res->is_success, 'valid request');
        is($res->content, qq{var foo = 1;\nvar bar = 2;\n}, 'right content');
        ok( !$res->header('X-Generated-On'), 'no generated header');
        ok( -f "t/static/generated/t1/$escaped", 'file is on disk' );

        $res = $server->(GET '/t1?foo.js&bar.js');
        ok($res->is_success, 'valid request');
        is($res->content, qq{var foo = 1;\nvar bar = 2;\n}, 'right content');
        ok( $res->header('X-Generated-On'), 'now we have generated header');
        ok( -f "t/static/generated/t1/$escaped", 'file is on disk' );

        unlink("t/static/generated/t1/$escaped");

        $res = $server->(GET '/t1?foo.js&bar.js');
        ok($res->is_success, 'valid request');
        is($res->content, qq{var foo = 1;\nvar bar = 2;\n}, 'right content');
        ok( !$res->header('X-Generated-On'), 'no generated header');
        ok( -f "t/static/generated/t1/$escaped", 'file is on disk again' );

    };
};

unlink("t/static/generated/t1/$escaped");
done_testing;
