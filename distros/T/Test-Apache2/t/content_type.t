use strict;
use warnings;
use Test::More tests => 2;
use t::Util;
use Apache2::Const -compile => qw(OK);

my $req = Test::Apache2::RequestRec->new;
$req->content_type('text/plain');
is(
    $req->headers_out->get('Content-Type'), 'text/plain',
    'content_type / headers_out'
);

my $resp = server_with_handler(
    sub {
        my ($self, $req) = @_;

        $req->content_type('text/plain');
        print "mod_perl 2.0 rocks!\n";
        return Apache2::Const::OK;
    }
)->get('/handler');

is(
    $resp->header('Content-Type'), 'text/plain',
    'response'
);
