#!perl

use strict;
use warnings;

use Test::More tests => 3;

use Net::WOT;

my $wot      = Net::WOT->new;
my $t_target = 'test_target';

isa_ok( $wot, 'Net::WOT' );

{
    no warnings qw/redefine once/;
    *Net::WOT::_create_link = sub {
        my ( $self, $target ) = @_;
        isa_ok( $self, 'Net::WOT' );
        is( $target, $t_target, 'correct target sent to _create_link' );
        exit;
    };
}

$wot->get_reputation($t_target);
