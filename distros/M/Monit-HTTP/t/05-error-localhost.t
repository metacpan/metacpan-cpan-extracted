#!perl -T

use lib 'lib';
use strict;
use warnings;
use Test::More tests => 1;

use Monit::HTTP ':constants';

eval {
    my $hd = new Monit::HTTP();
    $hd->get_services;
} or do {
    like $@, qr{Error while connecting}
};

