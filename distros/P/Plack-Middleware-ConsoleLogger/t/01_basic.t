use strict;
use Plack::Test;

use Test::More;
use HTTP::Request::Common;
use Plack::Builder;

my $app = sub {
    my $env     = shift;
    my $content = "<html><body>this is foo</body></html>";
    $env->{'psgix.logger'}->(
        {
            level   => 'debug',
            message => 'this is a message'
        }
    );
    $env->{'psgix.logger'}->(
        {
            level   => 'error',
            message => 'this is an error'
        }
    );
    $env->{'psgix.logger'}->({ level => "error", message => "Foo\nBar" });
    return [ 200, [ 'Content-Type' => 'text/html' ], [$content] ];
};

$app = builder {
    enable "ConsoleLogger";
    $app;
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/" );
    like $res->content, qr/console\.debug/, 'content matched';
    like $res->content, qr/console\.error/, 'content matched';
    like $res->content, qr/Foo\\u000aBar/, "newline escaped";
};

done_testing;
