package t::Net::ACME::HTTP::Response;

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
use Test::Exception;

use JSON ();

use Net::ACME::HTTP::Response ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_new : Tests(6) {
    my ($self) = @_;

    my $resp = Net::ACME::HTTP::Response->new(
        {
            url     => 'http://what',
            status  => '207',
            reason  => 'Whut',
            content => JSON::encode_json( { foo => 5 } ),
            headers => {
                link => [
                    '<http://ha/ha>;rel="ha"',
                    '<http://ho/ho>;rel="ho"',
                    'I just gotta be me',
                ],
            },
        },
    );

    isa_ok(
        $resp,
        'HTTP::Tiny::UA::Response',
        'instance of this class',
    );

    {
        my @warn;
        local $SIG{'__WARN__'} = sub { push @warn, @_ };

        is_deeply(
            { $resp->links() },
            {
                ha => 'http://ha/ha',
                ho => 'http://ho/ho',
            },
            'links()',
        );

        cmp_deeply(
            \@warn,
            [
                re(qr<I just gotta be me>),
            ],
            'links() warns on an unrecognized link',
        );
    }

    is_deeply(
        $resp->content_struct(),
        { foo => 5 },
        'content_struct()',
    );

    throws_ok(
        sub { $resp->die_because_unexpected() },
        'Net::ACME::X::UnexpectedResponse',
        'die_because_unexpected() throws',
    );

    my $err = $@;

    cmp_deeply(
        $err,
        methods(
            [ get => 'uri' ]     => 'http://what',
            [ get => 'status' ]  => '207',
            [ get => 'reason' ]  => 'Whut',
            [ get => 'headers' ] => { link => ignore() },
        ),
        '… and the error has what we expect',
    );

    return;
}

1;
