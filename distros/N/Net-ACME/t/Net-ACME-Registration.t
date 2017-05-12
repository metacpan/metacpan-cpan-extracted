package t::Net::ACME::Registration;

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

use Net::ACME::Registration ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub do_tests : Tests(1) {
    my ($self) = @_;

    my %params = map { $_ => "the_$_" } qw(
      uri
      agreement
      key
      terms_of_service
    );

    my $reg = Net::ACME::Registration->new(%params);

    cmp_deeply(
        $reg,
        methods(%params),
        'registration object accessor methods',
    );

    return;
}

1;
