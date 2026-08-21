#!/usr/bin/env perl

use v5.38;
use Test::More;
use Test::Fatal qw(exception);
use experimental 'class';

use PAGI::FastAPI::Response::Redirect qw(redirect_to);

class MockContext {
    field $status_code = 200;
    field $headers     = {};

    method status ($code = undef) {
        $status_code = $code if defined $code;
        return $status_code;
    }

    method set_header ($k, $v) {
        $headers->{$k} = $v;
    }

    method get_headers () { return $headers }
}

subtest 'redirect_to() defaults to 302 and sets Location' => sub {
    my $c   = MockContext->new;
    my $res = redirect_to('/new-path');
    $res->prepare_headers($c);

    is($c->status, 302, 'defaults to 302 Found');
    is($c->get_headers->{location}, '/new-path', 'Location header set');
    is($res->body, '', 'body defaults to empty');
};

subtest 'redirect_to() accepts an explicit status override' => sub {
    my $c   = MockContext->new;
    my $res = redirect_to('/permanent', status => 301);
    $res->prepare_headers($c);

    is($c->status, 301, 'explicit status honored');
    is($c->get_headers->{location}, '/permanent', 'Location header set');
};

subtest 'Direct construction requires a non-empty location' => sub {
    # Omitting 'location' entirely is caught by Perl's own required-param
    # enforcement for 'field $location :param;' (no default), that fires
    # before our ADJUST block even runs, so the message here is Perl's own,
    # not ours.
    like(
        exception { PAGI::FastAPI::Response::Redirect->new(status => 302) },
        qr/Required parameter 'location' is missing/,
        'omitting location entirely dies via the constructor-level required-param check',
    );

    # An explicitly-empty string DOES satisfy Perl's required-param check
    # (a value was passed), so this case is only caught by our own ADJUST
    # block's 'length $location' check, this is the one case where our
    # custom message actually fires.
    like(
        exception { PAGI::FastAPI::Response::Redirect->new(location => '', status => 302) },
        qr/requires a 'location' argument/,
        'an empty-string location is caught by our own ADJUST check, not Perl\'s',
    );
};

subtest 'Direct construction with explicit status (bypassing redirect_to)' => sub {
    my $c   = MockContext->new;
    my $res = PAGI::FastAPI::Response::Redirect->new(
        location => '/direct',
        status   => 307,
    );
    $res->prepare_headers($c);

    is($c->status, 307, 'status from direct constructor honored');
    is($c->get_headers->{location}, '/direct', 'Location header set via direct construction');
};

subtest 'isa PAGI::FastAPI::Response (required for the core dispatcher to recognize it)' => sub {
    my $res = redirect_to('/x');
    isa_ok($res, 'PAGI::FastAPI::Response');
};

done_testing;
