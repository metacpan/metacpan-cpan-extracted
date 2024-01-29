use Test::More tests => 6;
use Test::Exception;

use Net::SSLeay qw(MBSTRING_ASC MBSTRING_UTF8 EVP_PK_RSA EVP_PKT_SIGN EVP_PKT_ENC);

use File::Basename qw(dirname);
use Cwd            qw(abs_path);

use strict;
use warnings;
use autodie;

# Pre-requisite test to create key and certificate files, as used by later tests.

my $cert_dir = abs_path(dirname(__FILE__) . '/certificates');

sub generate_key {
    my $bits = shift;

    my $key  = Net::SSLeay::EVP_PKEY_new();
    my $rsa  = Net::SSLeay::RSA_generate_key($bits, &Net::SSLeay::RSA_F4);
    Net::SSLeay::EVP_PKEY_assign_RSA($key,$rsa);

    return $key;
}

sub create_private_key_file {
    my ($key, $name) = @_;

    my $pem_privkey = Net::SSLeay::PEM_get_string_PrivateKey($key);
    like($pem_privkey, qr/-----BEGIN (RSA )?PRIVATE KEY-----/, "$name PEM_get_string_PrivateKey+nopasswd");

    open my $fh, "> $cert_dir/$name.key";
    print $fh $pem_privkey;
}

sub create_public_cert_file {
    my ($key, $name, $serial, $before, $after) = @_;

    my $x509ss = Net::SSLeay::X509_new();
    Net::SSLeay::X509_set_version($x509ss, 0);
    my $sn = Net::SSLeay::X509_get_serialNumber($x509ss);
    Net::SSLeay::P_ASN1_INTEGER_set_hex($sn, $serial);

    my $b = Net::SSLeay::X509_gmtime_adj(Net::SSLeay::X509_get_notBefore($x509ss), $before);
    my $a = Net::SSLeay::X509_gmtime_adj(Net::SSLeay::X509_get_notAfter($x509ss),  $after);
    # warn "notBefore=", Net::SSLeay::P_ASN1_TIME_get_isotime($b), "\n";
    # warn "notAfter=",  Net::SSLeay::P_ASN1_TIME_get_isotime($a), "\n";

    Net::SSLeay::X509_set_pubkey($x509ss,$key);
    my $subject = Net::SSLeay::X509_get_subject_name($x509ss);
    Net::SSLeay::X509_NAME_add_entry_by_txt($subject, "commonName", MBSTRING_UTF8, $name);
    Net::SSLeay::X509_set_issuer_name($x509ss, Net::SSLeay::X509_get_subject_name($x509ss));

    my $sha1_digest = Net::SSLeay::EVP_get_digestbyname("sha1");
    Net::SSLeay::X509_sign($x509ss, $key, $sha1_digest);

    my $crt_pem = Net::SSLeay::PEM_get_string_X509($x509ss);
    like($crt_pem, qr/-----BEGIN CERTIFICATE-----/, "$name PEM_get_string_X509");

    open my $fh, "> $cert_dir/$name.cert";
    print $fh $crt_pem;
}

sub create_key_cert_files {
    my $bits = shift;
    my $key = generate_key($bits);
    create_private_key_file($key, @_);
    create_public_cert_file($key, @_);
}

my $days_100 = 60*60*24*100;

create_key_cert_files(2048, 'test.1', 'ABCDEF', 0, $days_100);
create_key_cert_files(2048, 'test.2', 'FEDCBA', 0, $days_100);

create_key_cert_files(2048, 'expired.1', 'DEAD', -$days_100, -60);
