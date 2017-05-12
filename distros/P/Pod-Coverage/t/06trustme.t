#!/usr/bin/perl -w
use strict;
use Test::More tests => 10;
use lib 't/lib';

BEGIN {
    use_ok( 'Pod::Coverage' );
    use_ok( 'Pod::Coverage::ExportOnly' );
}

my $obj = new Pod::Coverage package => 'Trustme';
isa_ok( $obj, 'Pod::Coverage' );
is($obj->coverage, 3/7, "without private or trustme it gets it right");

$obj = new Pod::Coverage package => 'Trustme', private => [qr/^private$/];
isa_ok( $obj, 'Pod::Coverage' );
is($obj->coverage, 3/6, "with just private it gets it right");

$obj = new Pod::Coverage
    package => 'Trustme',
    private => [qr/^private$/],
    trustme => [qr/u/];
isa_ok( $obj, 'Pod::Coverage' );
is($obj->coverage, 5/6, "with private and trustme it gets it right");

$obj = new Pod::Coverage
    package => 'Trustme',
    trustme => [qr/u/];
isa_ok( $obj, 'Pod::Coverage' );
is($obj->coverage, 5/7, "with just trustme it gets it right");
