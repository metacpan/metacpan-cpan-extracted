#!/usr/bin/perl

use lib 't/lib';
use Digest::MD5;
use SPVMImpl;
Digest::MD5::is_spvm();
die unless $INC{'Digest/MD5.pm'} =~ /\bblib\b/;

use strict;
use warnings;

use Test::More tests => 35;
use Digest::MD5;

foreach my $length (
    1..17,
    31..33,
    63..65,
    127..129,
    191..193,
    1023..1025,
    2047..2049,
) {
    my $string =  'a' x $length;

    my $expect = do {
        my $ctx = Digest::MD5->new;
        $ctx->add($string);
        $ctx->add($string);
        $ctx->add($string);
        $ctx->hexdigest;
    };

    my $got = do {
        my $ctx1 = Digest::MD5->new;
        $ctx1->add($string);

        my $ctx2 = Digest::MD5->new;
        $ctx2->context( $ctx1->context );
        $ctx2->add($string);

        my $ctx3 = Digest::MD5->new;
        $ctx3->context( $ctx2->context );
        $ctx3->add($string);

        $ctx3->hexdigest;
    };

    is $got, $expect, "[$length] saved context";
}
