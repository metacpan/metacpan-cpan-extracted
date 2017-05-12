package t::Net::ACME::Authorization::Pending;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use parent qw(
  Test::Class
);

use Test::More;
use Test::NoWarnings;
use Test::Deep;

use Net::ACME::Error ();

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::ACME ();

use JSON ();

use Net::ACME::RetryAfter             ();
use Net::ACME::Authorization::Pending ();

use Net::ACME::HTTP           ();
use Net::ACME::HTTP::Response ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_poll : Tests(7) {
    my ($self) = @_;

    my $class = 'Net::ACME::Authorization::Pending';

    my $pauthz = $class->new(
        uri        => 'http://where/to',
        challenges => [
            bless( {}, 'Net::ACME::Challenge::Pending' ),
        ],
    );

    Test::ACME::test_poll_response($pauthz);

    my $get_todo_cr;

    no warnings 'redefine';
    local *Net::ACME::HTTP::get = sub {
        my ( undef, $url ) = @_;
        die "unknown url: “$url”" if $url ne 'http://where/to';

        $get_todo_cr->();
    };

    #----------------------------------------------------------------------

    $get_todo_cr = sub {
        return Net::ACME::HTTP::Response->new(
            {
                status  => 200,
                content => JSON::encode_json(
                    {
                        status => 'invalid',

                        challenges => [
                            {
                                type   => 'http-01',
                                status => 'invalid',
                                error  => {
                                    type   => 'urn:ietf:params:acme:error:connection',
                                    detail => 'Well, shoot.',
                                },
                            },
                        ],
                    }
                ),
            },
        );
    };

    my $authz = $pauthz->poll();

    isa_ok(
        $authz,
        'Net::ACME::Authorization',
        'poll() return when the authorization failed',
    );

    cmp_deeply(
        $authz,
        listmethods(
            status     => ['invalid'],
            challenges => [
                all(
                    isa('Net::ACME::Challenge'),
                    methods(
                        status => 'invalid',
                        error  => all(
                            isa('Net::ACME::Error'),
                            methods(
                                type   => 'urn:ietf:params:acme:error:connection',
                                detail => 'Well, shoot.',
                            ),
                        ),
                    ),
                ),
            ],
        ),
        'invalid authorization object, parsed deeply',
    );

    #----------------------------------------------------------------------

    $get_todo_cr = sub {
        return Net::ACME::HTTP::Response->new(
            {
                status  => 200,
                content => JSON::encode_json(
                    {
                        status     => 'valid',
                        challenges => [
                            {
                                type   => 'http-01',
                                status => 'valid',
                            },
                        ],
                    }
                ),
            },
        );
    };

    $authz = $pauthz->poll();

    isa_ok(
        $authz,
        'Net::ACME::Authorization',
        'poll() return when the authorization succeeded',
    );

    cmp_deeply(
        $authz,
        listmethods(
            status     => ['valid'],
            challenges => [
                all(
                    isa('Net::ACME::Challenge'),
                    methods(
                        status => 'valid',
                        error  => undef,
                    ),
                ),
            ],
        ),
        'valid authorization object, parsed deeply',
    );

    return;
}

1;
