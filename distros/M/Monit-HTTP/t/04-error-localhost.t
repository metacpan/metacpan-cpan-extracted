#!perl

use strict;
use warnings;
use Test2::V1 '-import';
plan(1);
use Test::Trap qw/ :on_fail(diag_all) /;

use Monit::HTTP ':constants';

my @r = trap {
    my $hd = Monit::HTTP->new();
    $hd->get_services;
};
like( $trap->die, qr{Error while connecting}, 'Fail to connect to nothing' );
