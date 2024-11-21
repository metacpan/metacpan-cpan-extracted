use 5.008_007;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use Getopt::Long 'GetOptions';

GetOptions(
  'meta' => \my $meta,
  'no-build-spvm-modules' => \my $no_build_spvm_modules,
);

if ($meta) {
  $no_build_spvm_modules = 1;
}

unless ($meta) {
  # Do something such as environment check.
}

my %configure_and_runtime_requires = ('SPVM' => '0.990029');
WriteMakefile(
  NAME => 'SPVM::Net::SSLeay',
  VERSION_FROM => 'lib/SPVM/Net/SSLeay.pm',
  LICENSE => 'mit',
  ($] >= 5.005 ?
    (ABSTRACT_FROM => 'lib/SPVM/Net/SSLeay.pm',
     AUTHOR => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
  test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'},
  clean => {FILES => ['.spvm_build', 't/.spvm_build']},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/yuki-kimoto/SPVM-Net-SSLeay.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-Net-SSLeay',
      },
    },
    no_index => {
      directory => [],
    }
  },
  NORECURS => 1,
  CONFIGURE_REQUIRES => {
    %configure_and_runtime_requires,
  },
  PREREQ_PM         => {
    %configure_and_runtime_requires,
  },
  TEST_REQUIRES => {
    'SPVM::Mozilla::CA' => '0.001',
    'SPVM::IO' => '0.204003',
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
    
    local @INC = ('lib', @INC);
    
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::BIO');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::Constant');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::DH');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::EC_KEY');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::ERR');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::PEM');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::SSL_CTX');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::SSL_METHOD');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::SSL_SESSION');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::SSL_CIPHER');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::X509');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::X509_NAME');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::X509_CRL');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::X509_STORE');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::X509_STORE_CTX');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::X509_VERIFY_PARAM');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OPENSSL');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OPENSSL_INIT_SETTINGS');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::RAND');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::EVP');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::EVP_MD');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::EVP_PKEY');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::EVP_CIPHER_CTX');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::ASN1_OBJECT');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::ASN1_TIME');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::ASN1_GENERALIZEDTIME');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::ASN1_INTEGER');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::ASN1_ENUMERATED');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OBJ');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::DER');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OCSP');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OCSP_REQUEST');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OCSP_RESPONSE');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OCSP_BASICRESP');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OCSP_CERTID');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OCSP_SINGLERESP');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::OCSP_ONEREQ');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Net::SSLeay::PKCS12');
  }
  
  return $make_rule;
}

1;
