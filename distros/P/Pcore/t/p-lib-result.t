#!/usr/bin/env perl

package main v0.1.0;

use Pcore -res;
use Test::More;
use Pcore::Util::Result::Class;

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

my $data1 = [    #
    [ 200, 200, 'OK' ],
    [ [ 200, 'OK1' ],           200, 'OK1' ],
    [ [ 200, $STATUS_REASON1 ], 200, '11' ],
    [ res(200), 200, 'OK' ],
    [ [ res(200), 'OK1' ], 200, 'OK1' ],

    [ [ 200,      res( [300] ) ], 200, res(300)->{reason} ],
    [ [ res(200), res( [300] ) ], 200, res(300)->{reason} ],
];

for my $t ( $data1->@* ) {
    my $res = res $t->[0];
    ok( $res->{status} == $t->[1] && $res->{reason} eq $t->[2] );

    $res = Pcore::Util::Result::Class->new( { status => $t->[0] } );
    ok( $res->{status} == $t->[1] && $res->{reason} eq $t->[2] );

    $res = Pcore::Util::Result::Class->new;
    $res->set_status( $t->[0] );
    ok( $res->{status} == $t->[1] && $res->{reason} eq $t->[2] );
}

our $TESTS = $data1->@* * 3;
plan tests => $TESTS;
done_testing $TESTS;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 34, 37, 41           | TestingAndDebugging::RequireTestLabels - Test without a label                                                  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=cut
