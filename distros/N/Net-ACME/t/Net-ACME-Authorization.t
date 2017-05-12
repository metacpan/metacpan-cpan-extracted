package t::Net::ACME::Authorization;

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

use Net::ACME::Authorization ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub do_tests : Tests(5) {
    my ($self) = @_;

    throws_ok(
        sub {
            Net::ACME::Authorization->new(
                status => 'the_status',
                challenges => [ {} ],
            );
        },
        'Net::ACME::X::InvalidParameter',
        'die() if “challenges” has an unblessed hashref',
    );
    my $err = $@;

    like( $err->to_string(), qr<challenges>, '… and the error gives the parameter name' ) or diag explain $err;

    my $c = bless [], 'Net::ACME::Challenge';

    my $authz = Net::ACME::Authorization->new(
        status     => 'the_status',
        challenges => [$c],
    );

    is( $authz->status(), 'the_status', 'status()' );
    is_deeply(
        [ $authz->challenges() ],
        [$c],
        'challenges()',
    );

    throws_ok(
        sub { scalar $authz->challenges() },
        'Call::Context::X',
        'challenges() - forbid scalar context',
    );

    return;
}

1;
