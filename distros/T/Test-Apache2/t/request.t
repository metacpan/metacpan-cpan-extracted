use strict;
use warnings;
use Test::More tests => 1;
use t::Util;
use Apache2::Const -compile => qw(OK);

server_with_handler(
    sub {
        my ($self, $req) = @_;

        is($req->method, 'GET', 'method');

        $req->content_type('text/plain');
        print "mod_perl 2.0 rocks!\n";
        return Apache2::Const::OK;
    }
)->get('/handler');
