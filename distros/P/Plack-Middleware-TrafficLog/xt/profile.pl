#!/usr/bin/perl -d:NYTProf

use lib 'lib', '../lib';

use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $test = sub {
    my @args = @_;
    return sub {
        my ($req) = @_;
        my $app = builder {
            enable 'Plack::Middleware::TrafficLog', logger => sub { }, @args;
            sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "OK\nOK\n" ] ] };
        };
        test_psgi $app, sub { $_[0]->($req) };
    };
};

my $req = POST 'http://example.com/', Content => "TEST\nTEST\n";
$req->header('Host' => 'example.com', 'Content-Type' => 'text/plain');

foreach (1..10000) {
    $test->()->($req);
};

print "nytprof.out data collected. Call nytprofhtml --open\n";
