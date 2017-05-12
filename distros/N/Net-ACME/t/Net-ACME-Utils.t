package t::Net::ACME::Utils;

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

use Net::ACME::Utils ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_verify_token : Tests(3) {
    throws_ok(
        sub { Net::ACME::Utils::verify_token('invalid/token') },
        'Net::ACME::X::InvalidParameter',
        'invalid token exception',
    );
    my $err = $@;

    like( $err->to_string(), qr<invalid/token>, '… and the invalid token is in the message' );

    lives_ok(
        sub { Net::ACME::Utils::verify_token('valid_-token') },
        'valid token',
    );

    return;
}

1;
