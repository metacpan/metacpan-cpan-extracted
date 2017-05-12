use strict;
use warnings;
use Test::More tests => 2;
use t::Util;
use Apache2::Const -compile => qw(OK);

my $req = Test::Apache2::RequestRec->new;
$req->status(404);
is(
    $req->status, 404,
    'status'
);

my $resp = server_with_handler(
    sub {
        my ($self, $req) = @_;

        $req->content_type('text/plain');
        $req->status(404);
        print "mod_perl 2.0 rocks!\n";
        return Apache2::Const::OK;
    }
)->get('/handler');

is(
    $resp->code, 404,
    'response'
);
