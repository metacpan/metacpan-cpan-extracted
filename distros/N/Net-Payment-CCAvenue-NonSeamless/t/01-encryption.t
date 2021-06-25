#!perl -T
use 5.006;
use strict;
use warnings;

use lib '../lib';

use Net::Payment::CCAvenue::NonSeamless;
use Test::More tests => 5;


BEGIN {
    use_ok( 'Net::Payment::CCAvenue::NonSeamless' ) || print "Bail out!\n";
}

my $foo = Net::Payment::CCAvenue::NonSeamless->new(
    encryption_key => 'DS45941482122848F972D0553RC65891',
    access_code => 'AAAF02FA71CL81FVLC',
    merchant_id => '41231',
    currency => 'AED',
    amount => '3.00',
    redirect_url => 'http://example.com/order/success_or_fail',
    cancel_url => 'http://example.com/order/cancel',
);

my $data_to_encrypt = 'amount=3.00&currency=AED';
my $encrypted_data  = 'a1d4e9181db919c21867f681bc587e7c97ed64b83d2806e6ff2d34a951a48469';
is ( $foo->encrypt_data($data_to_encrypt), $encrypted_data, 'Correct encryption');
is ( $foo->decrypt_data($encrypted_data), $data_to_encrypt, 'Correct decryption');
is ( $foo->encryption_key_md5, '8e342c37c3138fc7ae4462cb9b27930d', 'Correct MD5 created');
like ($foo->payment_form, qr/<form/, 'Payment form generated');
