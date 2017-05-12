#!/usr/local/cpanel/3rdparty/bin/perl -w
package t::Net::ACME::Constants;

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

use Net::ACME::Constants ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub check_constants : Tests(2) {
    my ($self) = @_;

    like(
        $Net::ACME::Constants::HTTP_01_CHALLENGE_DCV_DIR_IN_DOCROOT,
        qr<.>,
        'http-01 challenge dir constant',
    );

    like(
        $Net::ACME::Constants::VERSION,
        qr<.>,
        'VERSION constant',
    );

    return;
}

1;
