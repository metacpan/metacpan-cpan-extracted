#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';

my $object = x509_certificate(
    issuer =>
        'C=ZA, ST=Western Cape, L=Cape Town, O=Thawte Consulting cc, OU=Certification Services Division, CN=Thawte Server CA/emailAddress=server-certs@thawte.com',
    validity_not_before => '2016-03-12T12:00',
    validity_not_after  => '2016-08-21T12:00',
    subject             =>
        'C=US, ST=Maryland, L=Pasadena, O=Brent Baccala, OU=FreeSoft, CN=www.freesoft.org/emailAddress=baccala@freesoft.org',
    serial_number => '36:f7:d4:32:f4:ab:70:ea:d3:ce:98:6e:ea:99:93:49:32:0a:b7:06',
);

my @errors = $object->validate;

diag 'Basic X.509 certificate', "\n", "$object";

isnt "$object", '';

is $object->type, 'x509-certificate';

is @errors, 0;

done_testing();
