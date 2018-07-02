use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::XRay;
use HTTP::Request::Common;
use AWS::XRay qw/ capture /;
use t::Util qw/ reset segments /;

my $app = sub {
    my $env = shift;
    capture "myApp", sub {
        [200, ['Content-Type' => 'text/plain'], ["Hello World\n"]];
    };
};

$app = Plack::Builder::builder {
    enable "XRay",
        name          => "myTest",
        sampling_rate => 0.2,
    ;
    $app;
};

my $captured = 0;
for ( 1 .. 1000 ) {
    reset;
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        my @seg = segments(2);
        ok @seg == 2 || @seg == 0;
        $captured++ if @seg == 2;
    };
}
diag $captured;
ok $captured > 100;
ok $captured < 300;

done_testing;

