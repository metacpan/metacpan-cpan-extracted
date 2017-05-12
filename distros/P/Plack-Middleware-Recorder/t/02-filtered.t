use strict;
use warnings;

use HTTP::Request::Common;
use File::Temp;
use Plack::Builder;
use Plack::VCR;
use Plack::Test;
use Test::More tests => 7;

my $tempfile = File::Temp->new;
close $tempfile;

my $app = builder {
    enable_if { $_[0]{'REQUEST_URI'} !~ /foo/ } 'Recorder', output => $tempfile->filename;

    sub {
        [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    $cb->(GET '/');
    $cb->(GET '/foo');
    $cb->(GET '/bar');
};

my $vcr = Plack::VCR->new(filename => $tempfile->filename);
my $interaction;
my $req;

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'GET';
is $req->uri, '/';

$interaction = $vcr->next;
ok $interaction;
$req = $interaction->request;
is $req->method, 'GET';
is $req->uri, '/bar';

$interaction = $vcr->next;
ok ! $interaction;
