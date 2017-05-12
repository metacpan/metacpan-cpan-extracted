use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;

use_ok('Plack::Middleware::ComboLoader');

my $loader = Plack::Middleware::ComboLoader->new({
    roots => {
        't1' => {
            path => 't/static/js',
            processor => sub {
                return uc($_->slurp);
            }
        }
    }
});

$loader->wrap( sub {
    [ 200, [ 'Content-Type' => 'text/plain' ], [ 'app' ] ]
});

test_psgi $loader => sub {
    my $server = shift;
    subtest "transforming" => sub {
        my $res = $server->(GET '/t1?foo.js&bar.js');
        ok($res->is_success, 'valid request');
        is($res->content, qq{VAR FOO = 1;\nVAR BAR = 2;\n}, 'right transformed content');
    };
};

done_testing;
