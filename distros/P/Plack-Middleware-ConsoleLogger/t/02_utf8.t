use strict;
use Plack::Test;

use Test::More;
use HTTP::Request::Common;
use Plack::Builder;

my $app = sub {
    my $env     = shift;
    my $content = "<html><body>this is foo</body></html>";
    $env->{'psgix.logger'}->({ level => 'debug', message => "Hello \x{1234}" });
    $env->{'psgix.logger'}->({ level => "error", message => "Hello テスト" });
    return [ 200, [ 'Content-Type' => 'text/html' ], [$content] ];
};

$app = builder {
    enable "Lint";
    enable "ConsoleLogger";
    $app;
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/" );
    like $res->content, qr/console\.debug\("Hello \\u1234"\)/;
    like $res->content, qr/console\.error\("Hello テスト"\)/;
};

done_testing;
