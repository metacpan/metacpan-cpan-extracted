package Test::ACME;

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Net::ACME::HTTP           ();
use Net::ACME::HTTP::Response ();

#Three test assertions
sub test_poll_response {
    my ($pending_obj) = @_;

    my $get_todo_cr = sub {
        return Net::ACME::HTTP::Response->new(
            {
                status  => 202,
                headers => {
                    'retry-after' => 999999,
                },
            },
        );
    };

    no warnings 'redefine';
    local *Net::ACME::HTTP::get = sub {
        my ( undef, $url ) = @_;

        return $get_todo_cr->();
    };

    is(
        $pending_obj->poll(),
        undef,
        'poll() return when we get 202',
    );

    is(
        $pending_obj->is_time_to_poll(),
        0,
        'a 202 response with big Retry-After makes is_time_to_poll() false',
    );

    #----------------------------------------------------------------------

    $get_todo_cr = sub {
        return Net::ACME::HTTP::Response->new(
            {
                status => 277,
                url => 'http://where/to',
                reason => 'dunno',
            },
        );
    };

    throws_ok(
        sub { $pending_obj->poll() },
        'Net::ACME::X::UnexpectedResponse',
        'error when poll() returns an unrecognized (success) code',
    );

    return;
}

1;
