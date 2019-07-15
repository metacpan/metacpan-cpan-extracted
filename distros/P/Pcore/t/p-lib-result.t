#!/usr/bin/env perl

package main v0.1.0;

use Pcore -res;
use Test::More;
use Pcore::Lib::Result::Class;

my $STATUS_REASON1 = {
    200 => 11,
    201 => 12,
    202 => 13,
};

my $STATUS_REASON2 = {
    200 => 21,
    201 => 22,
    202 => 23,
};

package TestRes {
    use Pcore -class;

    extends qw[Pcore::Lib::Result::Class];

    sub get_status_reason ($self) { return $STATUS_REASON2 }
}

# res
my $data1 = [    #
    [ 200, 200, 'OK' ],
    [ [ 200, 'OK1' ], 200, 'OK1' ],
    [ [ 200, $STATUS_REASON1 ], 200, '11' ],
    [ res(200), 200, 'OK' ],
    [ [ res(200), 'OK1' ], 200, 'OK' ],
];

for my $t ( $data1->@* ) {
    my $res = res $t->[0];

    ok( $res->{status} == $t->[1] );
    ok( $res->{reason} eq $t->[2] );
}

our $TESTS = 10;
plan tests => $TESTS;
done_testing $TESTS;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 41, 42               | TestingAndDebugging::RequireTestLabels - Test without a label                                                  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=cut
