#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump qw( dump );
use Test::More;

use Net::FreshBooks::API;
use Net::FreshBooks::API::Recurring::AutoBill;

new_ok( 'Net::FreshBooks::API::Recurring::AutoBill' );
my $autobill = Net::FreshBooks::API::Recurring::AutoBill->new;

$autobill->gateway_name( 'PayPal Payflow Pro' );
$autobill->card->name( 'Tim Toady' );
$autobill->card->number( '4111 1111 1111 1111' );
$autobill->card->expiration->month( 12 );
$autobill->card->expiration->year( 2015 );

isa_ok( $autobill,       'Net::FreshBooks::API::Recurring::AutoBill' );
isa_ok( $autobill->card, 'Net::FreshBooks::API::Recurring::AutoBill::Card' );
isa_ok( $autobill->card->expiration,
    'Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration' );

ok( $autobill->gateway_name,     "gateway name: " . $autobill->gateway_name );
ok( $autobill->card->expiration, "card expiration" );
ok( $autobill->card->expiration->month,
    "card expiration month: " . $autobill->card->expiration->month );
ok( $autobill->card->expiration->year,
    "card expiration year: " . $autobill->card->expiration->year );

ok( $autobill->card->name,   "card name: " . $autobill->card->name );
ok( $autobill->card->number, "card number: " . $autobill->card->number );

diag( "alternate syntax" );
ok( $autobill->card->month,
    "card expiration month: " . $autobill->card->expiration->month );
ok( $autobill->card->year,
    "card expiration year: " . $autobill->card->expiration->year );

ok( $autobill->_validates, "all required fields have been filled" );

my $empty = Net::FreshBooks::API::Recurring::AutoBill->new;
ok( !$empty->_validates, "NOT all required fields have been filled" );

done_testing();
