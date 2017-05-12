use strict;
use warnings;
use lib 't/lib';

use Plack::Builder;
use Plack::Recorder::TestUtils;
use Plack::Test;
use Test::More tests => 8;

my @request_paths;
my $tempfile = File::Temp->new;
close $tempfile;

my $app = builder {
    enable 'Recorder', output => $tempfile->filename;
    enable sub {
        my ( $app ) = @_;

        return sub {
            my ( $env ) = @_;

            push @request_paths, $env->{'PATH_INFO'};

            return $app->($env);
        };
    };
    sub {
        [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
    };
};


test_psgi $app, sub {
    my ( $cb ) = @_;

    $cb->(GET '/foo');
    $cb->(GET '/recorder/stop');
    $cb->(GET '/bar');
    $cb->(GET '/recorder/start');
    $cb->(GET '/baz');
};

my $vcr = Plack::VCR->new(filename => $tempfile->filename);
my $interaction;
my $req;

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'GET';
is $req->uri, '/foo';

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'GET';
is $req->uri, '/baz';

$interaction = $vcr->next;
ok !$interaction;

is_deeply \@request_paths, ['/foo', '/bar', '/baz'];
