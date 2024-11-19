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
    serial_number      => '02:08:87:83:f2:13:58:1f:79:52:1e:66:90:0a:02:24:c9:6b:c7:dc',
    x509_v3_extensions => x509_v3_extensions_type(
        basic_constraints                   => 'critical,CA:TRUE, pathlen:0',
        name_constraints                    => 'permitted;IP:192.168.0.0/255.255.0.0',
        policy_contraints                   => 'requireExplicitPolicy:3',
        key_usage                           => 'critical, keyCertSign',
        extended_key_usage                  => 'critical,codeSigning,1.2.3.4',
        subject_key_identifier              => 'hash',
        authority_key_identifier            => 'keyid,issuer',
        subject_alternative_name            => 'email:my@other.address,RID:1.2.3.4',
        issuer_alternative_name             => 'issuer:copy',
        crl_distribution_points             => 'URI:http://myhost.com/myca.crl',
        inhibit_any_policy                  => '2',
        private_key_usage_period_not_before => '2016-03-12T12:00',
        private_key_usage_period_not_after  => '2018-03-12T12:00',
        certificate_policies                => '1.2.4.5, 1.1.3.'
    )
);

my @errors = $object->validate;

diag 'X.509 Certificate w/ V3 Extensions', "\n", "$object";

isnt "$object", '';

is $object->type, 'x509-certificate';

is @errors, 0;

done_testing();
