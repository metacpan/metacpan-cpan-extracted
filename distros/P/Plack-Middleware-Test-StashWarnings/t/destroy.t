use strict;
use warnings;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;
use Scalar::Util 'weaken';

use Plack::Middleware::Test::StashWarnings;
use Plack::Request;

my $app = sub {
    my $req = Plack::Request->new(shift);
    my $name = $req->param('name');
    return [ 200, ["Content-Type", "text/plain"], ["Hello $name!"] ];
};

my @warnings;
local $SIG{__WARN__} = sub {
    push @warnings, @_;
};

my $weak_mw;

# Plack::Middleware::Test::StashWarnings calls the old __WARN__ handler
# if TEST_VERBOSE is set.  Fake its existance for now, so that tests
# pass under both `prove -v` and `prove`
$ENV{TEST_VERBOSE} = 1;
{
    my $mw = Plack::Middleware::Test::StashWarnings->new;
    my $new_app = $mw->wrap($app);

    weaken($weak_mw = $mw);

    test_psgi $new_app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/");
        like $res->content, qr/Hello !/;
        is $res->content_type, 'text/plain';
    };

    is @warnings, 1, "Got the uninitialized value warning";
    like $warnings[0], qr/Use of uninitialized value (?:\$name )?in concatenation/;
    @warnings = ();
}

# XXX: on 5.8.x we have to explicitly trigger the destructor because there's a memory leak
# so the destructor isn't called til global destruction. which is actually *fine* except
# when you want to test for the destructor's behavior
if ($weak_mw) {
    $weak_mw->DESTROY;
}

is @warnings, 1, "Got 'uncaught warning' warning";
like $warnings[0], qr/Unhandled warning: Use of uninitialized value (?:\$name )?in concatenation/;

done_testing;

