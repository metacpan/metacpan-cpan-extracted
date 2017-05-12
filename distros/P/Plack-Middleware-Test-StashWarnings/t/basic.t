use strict;
use warnings;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Builder;
use Plack::Request;

use Storable 'thaw';

my $app = sub {
    my $req = Plack::Request->new(shift);
    my $name = $req->param('name');
    return [ 200, ["Content-Type", "text/plain"], ["Hello $name!"] ];
};

my $t = builder {
    enable "Test::StashWarnings";
    $app;
};

test_psgi $t, sub {
    my $cb = shift;

    my $res = $cb->(GET "/__test_warnings");
    is_deeply thaw($res->content), [];
    is $res->content_type, 'application/x-storable';

    $res = $cb->(GET "/?name=foo");
    like $res->content, qr/Hello foo!/;
    is $res->content_type, 'text/plain';

    $res = $cb->(GET "/__test_warnings");
    is_deeply thaw($res->content), [], 'no warnings';
    is $res->content_type, 'application/x-storable';

    $res = $cb->(GET "/");
    like $res->content, qr/Hello !/;
    is $res->content_type, 'text/plain';

    $res = $cb->(GET "/__test_warnings");
    my @warnings = @{ thaw($res->content) };
    is @warnings, 1, "one warning";
    like $warnings[0], qr/Use of uninitialized value (?:\$name )?in concatenation/;
    is $res->content_type, 'application/x-storable';
};

done_testing;

