package t::Net::ACME::Challenge;

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

use Net::ACME::Challenge ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub do_tests : Tests(5) {
    my ($self) = @_;

    my $obj = Net::ACME::Challenge->new();

    is( $obj->error(),  undef,     'error() when empty/undef' );
    is( $obj->status(), 'pending', 'status() - default value' );

    my $blank_err = bless( {}, 'Net::ACME::Error' );

    $obj = Net::ACME::Challenge->new(
        error  => $blank_err,
        status => 'haha',
    );

    is( $obj->error(),  $blank_err, 'error() when a real object' );
    is( $obj->status(), 'haha',     'status() (non-default)' );

    throws_ok(
        sub {
            Net::ACME::Challenge->new(
                error  => 'haha',
                status => 'haha',
            );
        },
        'Net::ACME::X::InvalidParameter',
        'error when “error” is a non-object',
    );

    return;
}

1;
