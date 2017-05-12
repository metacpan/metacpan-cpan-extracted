#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use Data::Dumper;
use Net::WholesaleSystem;

my $WholesaleSystem = Net::WholesaleSystem->new(
    resellerID => $ENV{resellerID},
    apiKey     => $ENV{apiKey},
    is_ote     => 1,

    #    debug      => 1,
);

my $balance = $WholesaleSystem->balanceQuery or die $WholesaleSystem->errstr;
print $balance . "\n";

=pod

my $data = $WholesaleSystem->generateCSR(
    'numOfYears' => '3',
    'country' => 'AU',
    'state'   => 'VIC',
    'city'    => 'Melbourne',
    'organisation' => 'VentraIP',
    'organisationUnit' => 'Systems Admin',
    'commonName' => 'forums.ventraip.com.au',
    'emailAddress' => 'webmaster@ventraip.com.au'
);
print Dumper(\$data);

=cut

my $csr = <<'CSR';
-----BEGIN CERTIFICATE REQUEST-----
MIIFETCCAvkCAQAwgcsxHzAdBgNVBAMTFmZvcnVtcy52ZW50cmFpcC5jb20uYXUx
CzAJBgNVBAYTAkFVMQwwCgYDVQQIEwNWSUMxFDASBgNVBAcTC0JlY29uc2ZpZWxk
MSswKQYDVQQKEyJWZW50cmFJUCBHcm91cCAoQXVzdHJhbGlhKSBQdHkgTHRkMR8w
HQYDVQQLExZTeXN0ZW1zIEFkbWluaXN0cmF0aW9uMSkwJwYJKoZIhvcNAQkBFhpt
YW5hZ2VtZW50QHZlbnRyYWlwLmNvbS5hdTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
ADCCAgoCggIBALi0K3PNh/gqBBZBZuROQZ0Oal6k+wMXJ48Yolfs7Jn459GKP77D
wb5JQLJk4rN2HeE2HjzQFGDnqr5nSgJ81gUh3ksq26xX4tp0d8OGruF0ugUzBOnL
bIdouKiLIV6x1Hq/h9rr74EI7uqaOaNi5tFyccyrdKhigkcNthWNIUQB2rntR8QD
+Lquou/mFN1swjTmjO3VixPT76Xc6/GXg+6zZRDVDakchCIU8JFQKSsuWk/0P/Z8
rMVsSzl04LuMRPQVR7a0io5YbfNF666KFI8B3ZxxQ63ermseVbWc8yMU4UMGWdvN
9BejJlbX0uRMkcmh1+lx81Tb/GHUTGBehxeumpSTjaiQ+EcIPKGQ0VE4RZoSZkz5
9rBCkZ/nYICT34Zn7oAKZIkFaJaMeInJ7zI4tCG+Dkood/Q7xv+dWolgBHOvK7sM
WstPW4801q8avzH0F3pb0Z3uRIMlOOTEx3AsVyKbIXzhGGJH1CtI618X7lC0NGVF
/KAzcR8lQEkEA7xIW+EcJH8ees/sK5dSrvbO0n3tmVaxCcoxDLXZued9TgqxanbT
AUKkgNjOODaEp7wHNBS71Hrk5lChNdHq1NUU86c7zaSC/nLPed2PEM4mORZ9wk3p
yKVG7XlZa4JxmXDpAybEmi9lG5Q9G0UdJ/lu3GGMbILxCecMvdwiU0otAgMBAAGg
ADANBgkqhkiG9w0BAQQFAAOCAgEAD0PkH0I0DZRq0QfiC8ARjkqftQcALXzEbQu4
HvaPhUhFJGpjcO7w9Evq/6v290G1CtxltpAkPfAy0DLAwoT81upvKMMsqKuSUufY
QACG7e1lAug7rRu1zyxHve/MTZvLKX0ud8mNGI5DItMmkdVs6N/M0XYWb5oQshAW
+cXg4ib+mQkwkNWQqOMnX3NDVVqQL12eDcnyShv7S8nXuRRK0PEgkUpBzWEHHGmh
M8W3+fhPuKjZVkyTZVZIFySJyk8RJEXRYKd3sxDQumjghlb+uUX8ztax/OELLaZu
HqnuOH1Q7YMLLEOl8/I4JXwrwnlL6h51dtaVN2MOQ4l4F1petpbjPZDkcUq4BAXr
sFe19yTZLJwBwOYSviLisRD3z2aQnmu+0dXqhbqOcSRrj7wAfv77jYoLsfyJL990
zZKA3CQYESW04O+eMrGQDj0l9P5XiAlhiRblGKJMsYjuKXfTTIi/Bibktnc+xLqV
MfmPPj6JyfrJ/tvgMJVlgLVmYA71Pnlj1nej7PeV4NDUIaF7IzVsYIthAXietzMV
/wRV8cLEZ/JL2xaBDgaSiEV3w7Pk/zkr4lmawxW8WbF4M01kZMGfs8WFMthr302U
xPXbUhzSki+0CuvvNsW7kHhdPtceNLFxEcNN1VJmDjwoVBLwTI3eRCn1NgfWtUEO
J7NWyzY=
-----END CERTIFICATE REQUEST-----
CSR

=pod

my $output = $WholesaleSystem->decodeCSR($csr);
if ($output) {
    print Dumper(\$output);
} else {
    print $WholesaleSystem->errstr . "\n";
}

=cut

=pod

{
    
    my $cert = $WholesaleSystem->purchaseSSLCertificate(
        csr             => $csr,
        'productID'		=> '55',
        'firstName'		=> 'SSL',
        'lastName'		=> 'Admin',
        'emailAddress'	=> 'management@ventraip.com.au',
        'address'		=> 'PO BOX 119',
        'city'			=> 'Beaconsfield',
        'state'			=> 'VIC',
        'postCode'		=> '3807',
        'country'		=> 'AU',
        'phone'			=> '+61.390245383',
        'fax'			=> '+61.380806481'
    ) or die $WholesaleSystem->errstr;
    print Dumper(\$cert);
}

=cut

=pod

my $all_certs = $WholesaleSystem->listAllCerts or die $WholesaleSystem->errstr;
print Dumper(\$all_certs);

my $output = $WholesaleSystem->resendDVEmail(1) or die $WholesaleSystem->errstr;
print Dumper(\$output);

my $output = $WholesaleSystem->cancelSSLCertificate(1) or die $WholesaleSystem->errstr;
print Dumper(\$output);

my $output = $WholesaleSystem->getSSLCertificate(2) or die $WholesaleSystem->errstr;
print Dumper(\$output);

my $output = $WholesaleSystem->getCertSimpleStatus(2) or die $WholesaleSystem->errstr;
print Dumper(\$output);

my $output = $WholesaleSystem->resendIssuedCertificateEmail(2) or die $WholesaleSystem->errstr;
print Dumper(\$output);

my $output = $WholesaleSystem->getDomainBeacon(2, 'forums.ventraip.com.au') or die $WholesaleSystem->errstr;
print Dumper(\$output);

my $output = $WholesaleSystem->checkDomainBeacon(2, 'forums.ventraip.com.au') or die $WholesaleSystem->errstr;
print Dumper(\$output);

=cut

1;
