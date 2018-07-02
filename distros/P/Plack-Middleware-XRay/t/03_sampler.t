use 5.12.0;
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
    [200, ['Content-Type' => 'text/plain'], ["Hello World\n"]];
};

AWS::XRay->sampler(sub { 0 }); # disable sample globally

$app = Plack::Builder::builder {
    enable "XRay",
        name    => "myTest",
        sampler => sub {
            my $env = shift;
            state %paths;
            return $paths{$env->{PATH_INFO}}++ == 0;
        },
    ;
    $app;
};

for my $itr ( 1 .. 3 ) {
    for my $path ( 1 .. 3 ) {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET "/$path");
        };
    }
}

capture "foo", sub { }; # must not be captured because disabled globally

my @seg = segments;
is scalar @seg => 3;
is $seg[0]->{http}->{request}->{url} => "http://localhost/1";
is $seg[1]->{http}->{request}->{url} => "http://localhost/2";
is $seg[2]->{http}->{request}->{url} => "http://localhost/3";

done_testing;

