#!/usr/bin/perl

# $Id: 05-cipher.t,v 1.5 2008/10/16 13:47:42 turnstep Exp $

use strict;
use warnings;
use Data::Dumper;

use vars qw( $CFG_FILE );
BEGIN { unshift @INC, 't/' }
require 'test-common.pl';

use Net::SSH::Perl::Cipher;
use Test::More;

my $KEY = pack "H128", ("0123456789ABCDEF" x 8);
my $PASS = pack "H16", ("0123456789ABCDEF");

my %TESTS;
BEGIN {
    %TESTS = (IDEA => 1, DES => 1, Blowfish => 1, DES3 => 1, AES256_CTR => 1, AES128_CBC => 1, ChachaPoly => 1, None => 1);

    my $num_tests = 0;
    for my $cname (keys %TESTS) {
        my $id = Net::SSH::Perl::Cipher::id($cname); ## no critic
        if (Net::SSH::Perl::Cipher::supported($id)) { ## no critic
            $num_tests += 12;
        }
        else {
            delete $TESTS{$cname};
        }
    }

    plan tests => $num_tests;
}

for my $cname (keys %TESTS) {
    my($ciph1, $ciph2, $enc);

    ## Need two separate cipher objects because they're stateful,
    ## ie. their state changes after performing an encryption or
    ## decryption. So we need to perform an encryption with a
    ## "fresh" cipher, and perform decryption with an equally
    ## "fresh" cipher.

    ## Test regular key encryption.
    $ciph1 = Net::SSH::Perl::Cipher->new($cname, $KEY);
    $ciph2 = Net::SSH::Perl::Cipher->new($cname, $KEY);
    _check_it($ciph1, $ciph2);

    ## Test encryption with an empty passphrase.
    $ciph1 = Net::SSH::Perl::Cipher->new_from_key_str($cname, '');
    $ciph2 = Net::SSH::Perl::Cipher->new_from_key_str($cname, '');
    _check_it($ciph1, $ciph2);

    ## Test encryption with a non-empty passphrase.
    $ciph1 = Net::SSH::Perl::Cipher->new_from_key_str($cname, $PASS);
    $ciph2 = Net::SSH::Perl::Cipher->new_from_key_str($cname, $PASS);
    _check_it($ciph1, $ciph2);
}

sub _check_it {
    my($ciph1, $ciph2) = @_;
	my $line = (caller)[2];
    ok($ciph1, "First argument was true from line $line");
    ok($ciph2, "Second argument was true from line $line");
    my($enc, $dec);
    $enc = $ciph1->encrypt(_checkbytes());
    $dec = $ciph2->decrypt($enc);
    ok(ord substr($dec, 0, 1) == ord substr($dec, 2, 1), "Values matched from line $line");
    ok(ord substr($dec, 1, 1) == ord substr($dec, 3, 1), "Values matched from line $line");
}

sub _checkbytes {
    my($check1, $check2) = (chr int rand 255, chr int rand 255);
    "$check1$check2$check1$check2" . "\0\0\0\0";
}
