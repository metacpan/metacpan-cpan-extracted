use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::GitHub::WebHook;

if ( eval { require Plack::Middleware::HubSignature; 1; } ) {
    test_psgi
        app    => Plack::App::GitHub::WebHook->new( secret => '42', access => ['allow'=> 'all'] ),
        client => sub {
            my $cb = shift;
            my $req = POST '/', Content => '{"life":"meaning"}';

            like $cb->($req)->code, qr/^40[03]$/, 'Forbidden';

            my $sha = 'edb56d1d298e47793683310fbc10bb51d15000c5';
            $req->header('X-Hub-Signature' => "sha1=$sha");
            is $cb->($req)->code, 202, 'Accepted';
            
            $req->header( 'X-Hub-Signature' => 'invalid signature' );
            like $cb->($req)->code, qr/^40[03]$/, 'Forbidden';
    }
} else {
    plan skip_all => 'test requires Plack::Middleware::HubSignature';
}

done_testing;
