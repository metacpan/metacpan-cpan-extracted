package t::Net::ACME::Error;

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

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub do_tests : Tests(3) {
    my ($self) = @_;

    for my $ns (qw( urn:ietf:params:acme:error urn:acme:error )) {
        my %params = (
            type     => "$ns:dnssec",
            title    => 'A Title',
            detail   => 'This is a detail.',
            status   => 400,
            instance => 'http://instance/link',
        );

        my $err = Net::ACME::Error->new(%params);

        cmp_deeply(
            $err,
            methods(
                %params,
                description => re(qr<DNSSEC>),
                to_string   => all(
                    re(qr<DNSSEC>),
                    re(qr<\Q$params{'type'}\E>),
                    re(qr<\Q$params{'detail'}\E>),
                ),
            ),
            "“$ns” namespace: “familiar” error with a known type",
        );
    }

    my $err = Net::ACME::Error->new(
        type => 'the:type',
    );

    cmp_deeply(
        $err,
        methods(
            type        => 'the:type',
            description => undef,
            to_string   => 'the:type',
            ( map { $_ => undef } qw( title status detail instance ) ),
        ),
        '“empty” error with unknown type',
    );

    return 1;
}

1;
