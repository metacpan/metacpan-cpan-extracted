
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Opsview::REST::TestUtils;

use HTTP::Tiny;

use Test::More tests => 14;
use Test::Exception;

BEGIN { use_ok 'Opsview::REST'; };

dies_ok { Opsview::REST->new() } "Die if no arguments passed";

my ($url, $user, $pass) = (qw( http://localhost/rest admin initial ));

SKIP: {
    skip 'No $ENV{OPSVIEW_REST_TEST} defined', 11
        if (not defined $ENV{OPSVIEW_REST_TEST});

    throws_ok { Opsview::REST->new(
        base_url => $ENV{OPSVIEW_REST_URL}  || $url,
        user     => 'user',
    ); } qr/Need either a pass or an auth_tkt/, 'Not pass nor ticket given';

    throws_ok { Opsview::REST->new(
        base_url => $ENV{OPSVIEW_REST_URL}  || $url,
        user     => 'incorrect_user',
        pass     => 'incorrect_pass',
    ); } 'Opsview::REST::Exception', "Incorrect credentials";

    is($@->status, 401, '401 status in exception');
    is($@->reason, 'Unauthorized', '"Unauthorized" reason in exception');
    ok(defined $@->message, 'Message defined in exception');

    my $ops = get_opsview(undef, undef, undef, ua => HTTP::Tiny->new);
    like($ops->ua->agent, qr/HTTP-Tiny/, 'Force user agent');

    $ops = get_opsview();
    like($ops->ua->agent, qr/Opsview-REST/, 'Default user agent');

    isa_ok($ops, 'Opsview::REST', "Object created");
    ok(defined $ops->headers->{'X-Opsview-Token'}, "Logged in");

    throws_ok {
        $ops->get('/no_valid_method')
    } 'Opsview::REST::Exception', 'Not existent method call died';

    is($@->status, 404, '404 status in exception');
    is($@->reason, 'Not Found', '"Not Found" reason in exception');
    ok(defined $@->message, 'Message defined in exception');

};

SKIP: {
    skip 'No $ENV{OPSVIEW_REST_TEST_AUTHTKT}', 1
        if (not defined $ENV{OPSVIEW_REST_TEST_AUTHTKT});

    # New instance to test login via auth_tkt
    my $ops = get_opsview_authtkt();
    ok(defined $ops->headers->{'X-Opsview-Token'}, "Logged in");
};

