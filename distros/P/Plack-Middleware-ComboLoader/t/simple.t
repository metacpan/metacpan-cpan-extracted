use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;

use_ok('Plack::Middleware::ComboLoader');

my $loader = Plack::Middleware::ComboLoader->new({
    roots => {
        't1'     => 't/static/js',
        't1/css' => 't/static/css'
    }
});

$loader->wrap( sub {
    [ 200, [ 'Content-Type' => 'text/plain' ], [ 'app' ] ]
});

test_psgi $loader => sub {
    my $server = shift;
    subtest "simple concat" => sub {
        my $res = $server->(GET '/t1?foo.js&bar.js');
        ok($res->is_success, 'valid request');
        is($res->content_type, 'application/javascript', 'right content type');
        is($res->content, qq{var foo = 1;\nvar bar = 2;\n}, 'right content');

        $res = $server->(GET '/t1?foo.js&bar.js&plain.txt');
        ok($res->is_success, 'valid request');
        is($res->content_type, 'plain/text', 'right mixed content type');
        is($res->content, qq{var foo = 1;\nvar bar = 2;\nhello\n}, 'right content');
    };

    subtest "missing files" => sub {
        my $res = $server->(GET '/t1?foo.js&missing.js');
        is($res->code, 400, 'bad request');
        is($res->content, q{Invalid resource requested: `missing.js` is not available.}, 'correct message');
    };

};

done_testing;
