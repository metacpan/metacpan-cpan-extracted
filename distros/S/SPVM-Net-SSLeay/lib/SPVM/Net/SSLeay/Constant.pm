package SPVM::Net::SSLeay::Constant;



1;

=head1 Name

SPVM::Net::SSLeay::Constant - OpenSSL Constants

=head1 Description

Net::SSLeay::Constant class of L<SPVM> has methods to get OpenSSL Constants.

=head1 Usage

  use Net::SSLeay::Constant as SSL;
  
  my $value = SSL->SSL_VERIFY_NONE;

=head1 Class Methods

=head2 OPENSSL_VERSION_TEXT

C<static method OPENSSL_VERSION_TEXT : string ();>

Returns the value of C<OPENSSL_VERSION_TEXT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ASN1_STRFLGS_ESC_CTRL

C<static method ASN1_STRFLGS_ESC_CTRL : int ();>

Returns the value of C<ASN1_STRFLGS_ESC_CTRL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ASN1_STRFLGS_ESC_MSB

C<static method ASN1_STRFLGS_ESC_MSB : int ();>

Returns the value of C<ASN1_STRFLGS_ESC_MSB>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ASN1_STRFLGS_ESC_QUOTE

C<static method ASN1_STRFLGS_ESC_QUOTE : int ();>

Returns the value of C<ASN1_STRFLGS_ESC_QUOTE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ASN1_STRFLGS_RFC2253

C<static method ASN1_STRFLGS_RFC2253 : int ();>

Returns the value of C<ASN1_STRFLGS_RFC2253>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PKS_DSA

C<static method EVP_PKS_DSA : int ();>

Returns the value of C<EVP_PKS_DSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PKS_EC

C<static method EVP_PKS_EC : int ();>

Returns the value of C<EVP_PKS_EC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PKS_RSA

C<static method EVP_PKS_RSA : int ();>

Returns the value of C<EVP_PKS_RSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PKT_ENC

C<static method EVP_PKT_ENC : int ();>

Returns the value of C<EVP_PKT_ENC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PKT_EXCH

C<static method EVP_PKT_EXCH : int ();>

Returns the value of C<EVP_PKT_EXCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PKT_EXP

C<static method EVP_PKT_EXP : int ();>

Returns the value of C<EVP_PKT_EXP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PKT_SIGN

C<static method EVP_PKT_SIGN : int ();>

Returns the value of C<EVP_PKT_SIGN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PK_DH

C<static method EVP_PK_DH : int ();>

Returns the value of C<EVP_PK_DH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PK_DSA

C<static method EVP_PK_DSA : int ();>

Returns the value of C<EVP_PK_DSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PK_EC

C<static method EVP_PK_EC : int ();>

Returns the value of C<EVP_PK_EC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_PK_RSA

C<static method EVP_PK_RSA : int ();>

Returns the value of C<EVP_PK_RSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 GEN_DIRNAME

C<static method GEN_DIRNAME : int ();>

Returns the value of C<GEN_DIRNAME>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 GEN_DNS

C<static method GEN_DNS : int ();>

Returns the value of C<GEN_DNS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 GEN_EDIPARTY

C<static method GEN_EDIPARTY : int ();>

Returns the value of C<GEN_EDIPARTY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 GEN_EMAIL

C<static method GEN_EMAIL : int ();>

Returns the value of C<GEN_EMAIL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 GEN_IPADD

C<static method GEN_IPADD : int ();>

Returns the value of C<GEN_IPADD>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 GEN_OTHERNAME

C<static method GEN_OTHERNAME : int ();>

Returns the value of C<GEN_OTHERNAME>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 GEN_RID

C<static method GEN_RID : int ();>

Returns the value of C<GEN_RID>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 GEN_URI

C<static method GEN_URI : int ();>

Returns the value of C<GEN_URI>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 GEN_X400

C<static method GEN_X400 : int ();>

Returns the value of C<GEN_X400>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 LIBRESSL_VERSION_NUMBER

C<static method LIBRESSL_VERSION_NUMBER : int ();>

Returns the value of C<LIBRESSL_VERSION_NUMBER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MBSTRING_ASC

C<static method MBSTRING_ASC : int ();>

Returns the value of C<MBSTRING_ASC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MBSTRING_BMP

C<static method MBSTRING_BMP : int ();>

Returns the value of C<MBSTRING_BMP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MBSTRING_FLAG

C<static method MBSTRING_FLAG : int ();>

Returns the value of C<MBSTRING_FLAG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MBSTRING_UNIV

C<static method MBSTRING_UNIV : int ();>

Returns the value of C<MBSTRING_UNIV>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MBSTRING_UTF8

C<static method MBSTRING_UTF8 : int ();>

Returns the value of C<MBSTRING_UTF8>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_OCSP_sign

C<static method NID_OCSP_sign : int ();>

Returns the value of C<NID_OCSP_sign>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_SMIMECapabilities

C<static method NID_SMIMECapabilities : int ();>

Returns the value of C<NID_SMIMECapabilities>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_X500

C<static method NID_X500 : int ();>

Returns the value of C<NID_X500>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_X509

C<static method NID_X509 : int ();>

Returns the value of C<NID_X509>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ad_OCSP

C<static method NID_ad_OCSP : int ();>

Returns the value of C<NID_ad_OCSP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ad_ca_issuers

C<static method NID_ad_ca_issuers : int ();>

Returns the value of C<NID_ad_ca_issuers>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_algorithm

C<static method NID_algorithm : int ();>

Returns the value of C<NID_algorithm>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_authority_key_identifier

C<static method NID_authority_key_identifier : int ();>

Returns the value of C<NID_authority_key_identifier>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_basic_constraints

C<static method NID_basic_constraints : int ();>

Returns the value of C<NID_basic_constraints>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_bf_cbc

C<static method NID_bf_cbc : int ();>

Returns the value of C<NID_bf_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_bf_cfb64

C<static method NID_bf_cfb64 : int ();>

Returns the value of C<NID_bf_cfb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_bf_ecb

C<static method NID_bf_ecb : int ();>

Returns the value of C<NID_bf_ecb>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_bf_ofb64

C<static method NID_bf_ofb64 : int ();>

Returns the value of C<NID_bf_ofb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_cast5_cbc

C<static method NID_cast5_cbc : int ();>

Returns the value of C<NID_cast5_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_cast5_cfb64

C<static method NID_cast5_cfb64 : int ();>

Returns the value of C<NID_cast5_cfb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_cast5_ecb

C<static method NID_cast5_ecb : int ();>

Returns the value of C<NID_cast5_ecb>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_cast5_ofb64

C<static method NID_cast5_ofb64 : int ();>

Returns the value of C<NID_cast5_ofb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_certBag

C<static method NID_certBag : int ();>

Returns the value of C<NID_certBag>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_certificate_policies

C<static method NID_certificate_policies : int ();>

Returns the value of C<NID_certificate_policies>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_client_auth

C<static method NID_client_auth : int ();>

Returns the value of C<NID_client_auth>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_code_sign

C<static method NID_code_sign : int ();>

Returns the value of C<NID_code_sign>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_commonName

C<static method NID_commonName : int ();>

Returns the value of C<NID_commonName>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_countryName

C<static method NID_countryName : int ();>

Returns the value of C<NID_countryName>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_crlBag

C<static method NID_crlBag : int ();>

Returns the value of C<NID_crlBag>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_crl_distribution_points

C<static method NID_crl_distribution_points : int ();>

Returns the value of C<NID_crl_distribution_points>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_crl_number

C<static method NID_crl_number : int ();>

Returns the value of C<NID_crl_number>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_crl_reason

C<static method NID_crl_reason : int ();>

Returns the value of C<NID_crl_reason>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_delta_crl

C<static method NID_delta_crl : int ();>

Returns the value of C<NID_delta_crl>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_cbc

C<static method NID_des_cbc : int ();>

Returns the value of C<NID_des_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_cfb64

C<static method NID_des_cfb64 : int ();>

Returns the value of C<NID_des_cfb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ecb

C<static method NID_des_ecb : int ();>

Returns the value of C<NID_des_ecb>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ede

C<static method NID_des_ede : int ();>

Returns the value of C<NID_des_ede>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ede3

C<static method NID_des_ede3 : int ();>

Returns the value of C<NID_des_ede3>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ede3_cbc

C<static method NID_des_ede3_cbc : int ();>

Returns the value of C<NID_des_ede3_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ede3_cfb64

C<static method NID_des_ede3_cfb64 : int ();>

Returns the value of C<NID_des_ede3_cfb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ede3_ofb64

C<static method NID_des_ede3_ofb64 : int ();>

Returns the value of C<NID_des_ede3_ofb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ede_cbc

C<static method NID_des_ede_cbc : int ();>

Returns the value of C<NID_des_ede_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ede_cfb64

C<static method NID_des_ede_cfb64 : int ();>

Returns the value of C<NID_des_ede_cfb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ede_ofb64

C<static method NID_des_ede_ofb64 : int ();>

Returns the value of C<NID_des_ede_ofb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_des_ofb64

C<static method NID_des_ofb64 : int ();>

Returns the value of C<NID_des_ofb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_description

C<static method NID_description : int ();>

Returns the value of C<NID_description>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_desx_cbc

C<static method NID_desx_cbc : int ();>

Returns the value of C<NID_desx_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_dhKeyAgreement

C<static method NID_dhKeyAgreement : int ();>

Returns the value of C<NID_dhKeyAgreement>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_dnQualifier

C<static method NID_dnQualifier : int ();>

Returns the value of C<NID_dnQualifier>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_dsa

C<static method NID_dsa : int ();>

Returns the value of C<NID_dsa>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_dsaWithSHA

C<static method NID_dsaWithSHA : int ();>

Returns the value of C<NID_dsaWithSHA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_dsaWithSHA1

C<static method NID_dsaWithSHA1 : int ();>

Returns the value of C<NID_dsaWithSHA1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_dsaWithSHA1_2

C<static method NID_dsaWithSHA1_2 : int ();>

Returns the value of C<NID_dsaWithSHA1_2>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_dsa_2

C<static method NID_dsa_2 : int ();>

Returns the value of C<NID_dsa_2>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_email_protect

C<static method NID_email_protect : int ();>

Returns the value of C<NID_email_protect>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ext_key_usage

C<static method NID_ext_key_usage : int ();>

Returns the value of C<NID_ext_key_usage>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ext_req

C<static method NID_ext_req : int ();>

Returns the value of C<NID_ext_req>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_friendlyName

C<static method NID_friendlyName : int ();>

Returns the value of C<NID_friendlyName>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_givenName

C<static method NID_givenName : int ();>

Returns the value of C<NID_givenName>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_hmacWithSHA1

C<static method NID_hmacWithSHA1 : int ();>

Returns the value of C<NID_hmacWithSHA1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_id_ad

C<static method NID_id_ad : int ();>

Returns the value of C<NID_id_ad>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_id_ce

C<static method NID_id_ce : int ();>

Returns the value of C<NID_id_ce>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_id_kp

C<static method NID_id_kp : int ();>

Returns the value of C<NID_id_kp>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_id_pbkdf2

C<static method NID_id_pbkdf2 : int ();>

Returns the value of C<NID_id_pbkdf2>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_id_pe

C<static method NID_id_pe : int ();>

Returns the value of C<NID_id_pe>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_id_pkix

C<static method NID_id_pkix : int ();>

Returns the value of C<NID_id_pkix>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_id_qt_cps

C<static method NID_id_qt_cps : int ();>

Returns the value of C<NID_id_qt_cps>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_id_qt_unotice

C<static method NID_id_qt_unotice : int ();>

Returns the value of C<NID_id_qt_unotice>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_idea_cbc

C<static method NID_idea_cbc : int ();>

Returns the value of C<NID_idea_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_idea_cfb64

C<static method NID_idea_cfb64 : int ();>

Returns the value of C<NID_idea_cfb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_idea_ecb

C<static method NID_idea_ecb : int ();>

Returns the value of C<NID_idea_ecb>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_idea_ofb64

C<static method NID_idea_ofb64 : int ();>

Returns the value of C<NID_idea_ofb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_info_access

C<static method NID_info_access : int ();>

Returns the value of C<NID_info_access>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_initials

C<static method NID_initials : int ();>

Returns the value of C<NID_initials>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_invalidity_date

C<static method NID_invalidity_date : int ();>

Returns the value of C<NID_invalidity_date>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_issuer_alt_name

C<static method NID_issuer_alt_name : int ();>

Returns the value of C<NID_issuer_alt_name>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_keyBag

C<static method NID_keyBag : int ();>

Returns the value of C<NID_keyBag>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_key_usage

C<static method NID_key_usage : int ();>

Returns the value of C<NID_key_usage>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_localKeyID

C<static method NID_localKeyID : int ();>

Returns the value of C<NID_localKeyID>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_localityName

C<static method NID_localityName : int ();>

Returns the value of C<NID_localityName>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_md2

C<static method NID_md2 : int ();>

Returns the value of C<NID_md2>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_md2WithRSAEncryption

C<static method NID_md2WithRSAEncryption : int ();>

Returns the value of C<NID_md2WithRSAEncryption>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_md5

C<static method NID_md5 : int ();>

Returns the value of C<NID_md5>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_md5WithRSA

C<static method NID_md5WithRSA : int ();>

Returns the value of C<NID_md5WithRSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_md5WithRSAEncryption

C<static method NID_md5WithRSAEncryption : int ();>

Returns the value of C<NID_md5WithRSAEncryption>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_md5_sha1

C<static method NID_md5_sha1 : int ();>

Returns the value of C<NID_md5_sha1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_mdc2

C<static method NID_mdc2 : int ();>

Returns the value of C<NID_mdc2>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_mdc2WithRSA

C<static method NID_mdc2WithRSA : int ();>

Returns the value of C<NID_mdc2WithRSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ms_code_com

C<static method NID_ms_code_com : int ();>

Returns the value of C<NID_ms_code_com>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ms_code_ind

C<static method NID_ms_code_ind : int ();>

Returns the value of C<NID_ms_code_ind>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ms_ctl_sign

C<static method NID_ms_ctl_sign : int ();>

Returns the value of C<NID_ms_ctl_sign>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ms_efs

C<static method NID_ms_efs : int ();>

Returns the value of C<NID_ms_efs>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ms_ext_req

C<static method NID_ms_ext_req : int ();>

Returns the value of C<NID_ms_ext_req>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ms_sgc

C<static method NID_ms_sgc : int ();>

Returns the value of C<NID_ms_sgc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_name

C<static method NID_name : int ();>

Returns the value of C<NID_name>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape

C<static method NID_netscape : int ();>

Returns the value of C<NID_netscape>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_base_url

C<static method NID_netscape_base_url : int ();>

Returns the value of C<NID_netscape_base_url>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_ca_policy_url

C<static method NID_netscape_ca_policy_url : int ();>

Returns the value of C<NID_netscape_ca_policy_url>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_ca_revocation_url

C<static method NID_netscape_ca_revocation_url : int ();>

Returns the value of C<NID_netscape_ca_revocation_url>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_cert_extension

C<static method NID_netscape_cert_extension : int ();>

Returns the value of C<NID_netscape_cert_extension>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_cert_sequence

C<static method NID_netscape_cert_sequence : int ();>

Returns the value of C<NID_netscape_cert_sequence>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_cert_type

C<static method NID_netscape_cert_type : int ();>

Returns the value of C<NID_netscape_cert_type>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_comment

C<static method NID_netscape_comment : int ();>

Returns the value of C<NID_netscape_comment>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_data_type

C<static method NID_netscape_data_type : int ();>

Returns the value of C<NID_netscape_data_type>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_renewal_url

C<static method NID_netscape_renewal_url : int ();>

Returns the value of C<NID_netscape_renewal_url>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_revocation_url

C<static method NID_netscape_revocation_url : int ();>

Returns the value of C<NID_netscape_revocation_url>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_netscape_ssl_server_name

C<static method NID_netscape_ssl_server_name : int ();>

Returns the value of C<NID_netscape_ssl_server_name>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ns_sgc

C<static method NID_ns_sgc : int ();>

Returns the value of C<NID_ns_sgc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_organizationName

C<static method NID_organizationName : int ();>

Returns the value of C<NID_organizationName>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_organizationalUnitName

C<static method NID_organizationalUnitName : int ();>

Returns the value of C<NID_organizationalUnitName>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbeWithMD2AndDES_CBC

C<static method NID_pbeWithMD2AndDES_CBC : int ();>

Returns the value of C<NID_pbeWithMD2AndDES_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbeWithMD2AndRC2_CBC

C<static method NID_pbeWithMD2AndRC2_CBC : int ();>

Returns the value of C<NID_pbeWithMD2AndRC2_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbeWithMD5AndCast5_CBC

C<static method NID_pbeWithMD5AndCast5_CBC : int ();>

Returns the value of C<NID_pbeWithMD5AndCast5_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbeWithMD5AndDES_CBC

C<static method NID_pbeWithMD5AndDES_CBC : int ();>

Returns the value of C<NID_pbeWithMD5AndDES_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbeWithMD5AndRC2_CBC

C<static method NID_pbeWithMD5AndRC2_CBC : int ();>

Returns the value of C<NID_pbeWithMD5AndRC2_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbeWithSHA1AndDES_CBC

C<static method NID_pbeWithSHA1AndDES_CBC : int ();>

Returns the value of C<NID_pbeWithSHA1AndDES_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbeWithSHA1AndRC2_CBC

C<static method NID_pbeWithSHA1AndRC2_CBC : int ();>

Returns the value of C<NID_pbeWithSHA1AndRC2_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbe_WithSHA1And128BitRC2_CBC

C<static method NID_pbe_WithSHA1And128BitRC2_CBC : int ();>

Returns the value of C<NID_pbe_WithSHA1And128BitRC2_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbe_WithSHA1And128BitRC4

C<static method NID_pbe_WithSHA1And128BitRC4 : int ();>

Returns the value of C<NID_pbe_WithSHA1And128BitRC4>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbe_WithSHA1And2_Key_TripleDES_CBC

C<static method NID_pbe_WithSHA1And2_Key_TripleDES_CBC : int ();>

Returns the value of C<NID_pbe_WithSHA1And2_Key_TripleDES_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbe_WithSHA1And3_Key_TripleDES_CBC

C<static method NID_pbe_WithSHA1And3_Key_TripleDES_CBC : int ();>

Returns the value of C<NID_pbe_WithSHA1And3_Key_TripleDES_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbe_WithSHA1And40BitRC2_CBC

C<static method NID_pbe_WithSHA1And40BitRC2_CBC : int ();>

Returns the value of C<NID_pbe_WithSHA1And40BitRC2_CBC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbe_WithSHA1And40BitRC4

C<static method NID_pbe_WithSHA1And40BitRC4 : int ();>

Returns the value of C<NID_pbe_WithSHA1And40BitRC4>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbes2

C<static method NID_pbes2 : int ();>

Returns the value of C<NID_pbes2>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pbmac1

C<static method NID_pbmac1 : int ();>

Returns the value of C<NID_pbmac1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs

C<static method NID_pkcs : int ();>

Returns the value of C<NID_pkcs>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs3

C<static method NID_pkcs3 : int ();>

Returns the value of C<NID_pkcs3>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs7

C<static method NID_pkcs7 : int ();>

Returns the value of C<NID_pkcs7>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs7_data

C<static method NID_pkcs7_data : int ();>

Returns the value of C<NID_pkcs7_data>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs7_digest

C<static method NID_pkcs7_digest : int ();>

Returns the value of C<NID_pkcs7_digest>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs7_encrypted

C<static method NID_pkcs7_encrypted : int ();>

Returns the value of C<NID_pkcs7_encrypted>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs7_enveloped

C<static method NID_pkcs7_enveloped : int ();>

Returns the value of C<NID_pkcs7_enveloped>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs7_signed

C<static method NID_pkcs7_signed : int ();>

Returns the value of C<NID_pkcs7_signed>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs7_signedAndEnveloped

C<static method NID_pkcs7_signedAndEnveloped : int ();>

Returns the value of C<NID_pkcs7_signedAndEnveloped>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs8ShroudedKeyBag

C<static method NID_pkcs8ShroudedKeyBag : int ();>

Returns the value of C<NID_pkcs8ShroudedKeyBag>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9

C<static method NID_pkcs9 : int ();>

Returns the value of C<NID_pkcs9>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9_challengePassword

C<static method NID_pkcs9_challengePassword : int ();>

Returns the value of C<NID_pkcs9_challengePassword>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9_contentType

C<static method NID_pkcs9_contentType : int ();>

Returns the value of C<NID_pkcs9_contentType>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9_countersignature

C<static method NID_pkcs9_countersignature : int ();>

Returns the value of C<NID_pkcs9_countersignature>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9_emailAddress

C<static method NID_pkcs9_emailAddress : int ();>

Returns the value of C<NID_pkcs9_emailAddress>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9_extCertAttributes

C<static method NID_pkcs9_extCertAttributes : int ();>

Returns the value of C<NID_pkcs9_extCertAttributes>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9_messageDigest

C<static method NID_pkcs9_messageDigest : int ();>

Returns the value of C<NID_pkcs9_messageDigest>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9_signingTime

C<static method NID_pkcs9_signingTime : int ();>

Returns the value of C<NID_pkcs9_signingTime>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9_unstructuredAddress

C<static method NID_pkcs9_unstructuredAddress : int ();>

Returns the value of C<NID_pkcs9_unstructuredAddress>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_pkcs9_unstructuredName

C<static method NID_pkcs9_unstructuredName : int ();>

Returns the value of C<NID_pkcs9_unstructuredName>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_private_key_usage_period

C<static method NID_private_key_usage_period : int ();>

Returns the value of C<NID_private_key_usage_period>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc2_40_cbc

C<static method NID_rc2_40_cbc : int ();>

Returns the value of C<NID_rc2_40_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc2_64_cbc

C<static method NID_rc2_64_cbc : int ();>

Returns the value of C<NID_rc2_64_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc2_cbc

C<static method NID_rc2_cbc : int ();>

Returns the value of C<NID_rc2_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc2_cfb64

C<static method NID_rc2_cfb64 : int ();>

Returns the value of C<NID_rc2_cfb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc2_ecb

C<static method NID_rc2_ecb : int ();>

Returns the value of C<NID_rc2_ecb>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc2_ofb64

C<static method NID_rc2_ofb64 : int ();>

Returns the value of C<NID_rc2_ofb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc4

C<static method NID_rc4 : int ();>

Returns the value of C<NID_rc4>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc4_40

C<static method NID_rc4_40 : int ();>

Returns the value of C<NID_rc4_40>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc5_cbc

C<static method NID_rc5_cbc : int ();>

Returns the value of C<NID_rc5_cbc>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc5_cfb64

C<static method NID_rc5_cfb64 : int ();>

Returns the value of C<NID_rc5_cfb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc5_ecb

C<static method NID_rc5_ecb : int ();>

Returns the value of C<NID_rc5_ecb>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rc5_ofb64

C<static method NID_rc5_ofb64 : int ();>

Returns the value of C<NID_rc5_ofb64>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ripemd160

C<static method NID_ripemd160 : int ();>

Returns the value of C<NID_ripemd160>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_ripemd160WithRSA

C<static method NID_ripemd160WithRSA : int ();>

Returns the value of C<NID_ripemd160WithRSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rle_compression

C<static method NID_rle_compression : int ();>

Returns the value of C<NID_rle_compression>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rsa

C<static method NID_rsa : int ();>

Returns the value of C<NID_rsa>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rsaEncryption

C<static method NID_rsaEncryption : int ();>

Returns the value of C<NID_rsaEncryption>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_rsadsi

C<static method NID_rsadsi : int ();>

Returns the value of C<NID_rsadsi>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_safeContentsBag

C<static method NID_safeContentsBag : int ();>

Returns the value of C<NID_safeContentsBag>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_sdsiCertificate

C<static method NID_sdsiCertificate : int ();>

Returns the value of C<NID_sdsiCertificate>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_secretBag

C<static method NID_secretBag : int ();>

Returns the value of C<NID_secretBag>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_serialNumber

C<static method NID_serialNumber : int ();>

Returns the value of C<NID_serialNumber>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_server_auth

C<static method NID_server_auth : int ();>

Returns the value of C<NID_server_auth>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_sha

C<static method NID_sha : int ();>

Returns the value of C<NID_sha>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_sha1

C<static method NID_sha1 : int ();>

Returns the value of C<NID_sha1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_sha1WithRSA

C<static method NID_sha1WithRSA : int ();>

Returns the value of C<NID_sha1WithRSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_sha1WithRSAEncryption

C<static method NID_sha1WithRSAEncryption : int ();>

Returns the value of C<NID_sha1WithRSAEncryption>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_shaWithRSAEncryption

C<static method NID_shaWithRSAEncryption : int ();>

Returns the value of C<NID_shaWithRSAEncryption>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_stateOrProvinceName

C<static method NID_stateOrProvinceName : int ();>

Returns the value of C<NID_stateOrProvinceName>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_subject_alt_name

C<static method NID_subject_alt_name : int ();>

Returns the value of C<NID_subject_alt_name>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_subject_key_identifier

C<static method NID_subject_key_identifier : int ();>

Returns the value of C<NID_subject_key_identifier>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_surname

C<static method NID_surname : int ();>

Returns the value of C<NID_surname>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_sxnet

C<static method NID_sxnet : int ();>

Returns the value of C<NID_sxnet>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_time_stamp

C<static method NID_time_stamp : int ();>

Returns the value of C<NID_time_stamp>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_title

C<static method NID_title : int ();>

Returns the value of C<NID_title>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_undef

C<static method NID_undef : int ();>

Returns the value of C<NID_undef>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_uniqueIdentifier

C<static method NID_uniqueIdentifier : int ();>

Returns the value of C<NID_uniqueIdentifier>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_x509Certificate

C<static method NID_x509Certificate : int ();>

Returns the value of C<NID_x509Certificate>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_x509Crl

C<static method NID_x509Crl : int ();>

Returns the value of C<NID_x509Crl>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NID_zlib_compression

C<static method NID_zlib_compression : int ();>

Returns the value of C<NID_zlib_compression>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OCSP_RESPONSE_STATUS_INTERNALERROR

C<static method OCSP_RESPONSE_STATUS_INTERNALERROR : int ();>

Returns the value of C<OCSP_RESPONSE_STATUS_INTERNALERROR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OCSP_RESPONSE_STATUS_MALFORMEDREQUEST

C<static method OCSP_RESPONSE_STATUS_MALFORMEDREQUEST : int ();>

Returns the value of C<OCSP_RESPONSE_STATUS_MALFORMEDREQUEST>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OCSP_RESPONSE_STATUS_SIGREQUIRED

C<static method OCSP_RESPONSE_STATUS_SIGREQUIRED : int ();>

Returns the value of C<OCSP_RESPONSE_STATUS_SIGREQUIRED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OCSP_RESPONSE_STATUS_SUCCESSFUL

C<static method OCSP_RESPONSE_STATUS_SUCCESSFUL : int ();>

Returns the value of C<OCSP_RESPONSE_STATUS_SUCCESSFUL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OCSP_RESPONSE_STATUS_TRYLATER

C<static method OCSP_RESPONSE_STATUS_TRYLATER : int ();>

Returns the value of C<OCSP_RESPONSE_STATUS_TRYLATER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OCSP_RESPONSE_STATUS_UNAUTHORIZED

C<static method OCSP_RESPONSE_STATUS_UNAUTHORIZED : int ();>

Returns the value of C<OCSP_RESPONSE_STATUS_UNAUTHORIZED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_BUILT_ON

C<static method OPENSSL_BUILT_ON : int ();>

Returns the value of C<OPENSSL_BUILT_ON>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_CFLAGS

C<static method OPENSSL_CFLAGS : int ();>

Returns the value of C<OPENSSL_CFLAGS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_CPU_INFO

C<static method OPENSSL_CPU_INFO : int ();>

Returns the value of C<OPENSSL_CPU_INFO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_DIR

C<static method OPENSSL_DIR : int ();>

Returns the value of C<OPENSSL_DIR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_ENGINES_DIR

C<static method OPENSSL_ENGINES_DIR : int ();>

Returns the value of C<OPENSSL_ENGINES_DIR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_FULL_VERSION_STRING

C<static method OPENSSL_FULL_VERSION_STRING : int ();>

Returns the value of C<OPENSSL_FULL_VERSION_STRING>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INFO_CONFIG_DIR

C<static method OPENSSL_INFO_CONFIG_DIR : int ();>

Returns the value of C<OPENSSL_INFO_CONFIG_DIR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INFO_CPU_SETTINGS

C<static method OPENSSL_INFO_CPU_SETTINGS : int ();>

Returns the value of C<OPENSSL_INFO_CPU_SETTINGS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INFO_DIR_FILENAME_SEPARATOR

C<static method OPENSSL_INFO_DIR_FILENAME_SEPARATOR : int ();>

Returns the value of C<OPENSSL_INFO_DIR_FILENAME_SEPARATOR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INFO_DSO_EXTENSION

C<static method OPENSSL_INFO_DSO_EXTENSION : int ();>

Returns the value of C<OPENSSL_INFO_DSO_EXTENSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INFO_ENGINES_DIR

C<static method OPENSSL_INFO_ENGINES_DIR : int ();>

Returns the value of C<OPENSSL_INFO_ENGINES_DIR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INFO_LIST_SEPARATOR

C<static method OPENSSL_INFO_LIST_SEPARATOR : int ();>

Returns the value of C<OPENSSL_INFO_LIST_SEPARATOR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INFO_MODULES_DIR

C<static method OPENSSL_INFO_MODULES_DIR : int ();>

Returns the value of C<OPENSSL_INFO_MODULES_DIR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INFO_SEED_SOURCE

C<static method OPENSSL_INFO_SEED_SOURCE : int ();>

Returns the value of C<OPENSSL_INFO_SEED_SOURCE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_MODULES_DIR

C<static method OPENSSL_MODULES_DIR : int ();>

Returns the value of C<OPENSSL_MODULES_DIR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_PLATFORM

C<static method OPENSSL_PLATFORM : int ();>

Returns the value of C<OPENSSL_PLATFORM>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_VERSION

C<static method OPENSSL_VERSION : int ();>

Returns the value of C<OPENSSL_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_VERSION_MAJOR

C<static method OPENSSL_VERSION_MAJOR : int ();>

Returns the value of C<OPENSSL_VERSION_MAJOR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_VERSION_MINOR

C<static method OPENSSL_VERSION_MINOR : int ();>

Returns the value of C<OPENSSL_VERSION_MINOR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_VERSION_NUMBER

C<static method OPENSSL_VERSION_NUMBER : int ();>

Returns the value of C<OPENSSL_VERSION_NUMBER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_VERSION_PATCH

C<static method OPENSSL_VERSION_PATCH : int ();>

Returns the value of C<OPENSSL_VERSION_PATCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_VERSION_STRING

C<static method OPENSSL_VERSION_STRING : int ();>

Returns the value of C<OPENSSL_VERSION_STRING>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 RSA_3

C<static method RSA_3 : int ();>

Returns the value of C<RSA_3>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 RSA_F4

C<static method RSA_F4 : int ();>

Returns the value of C<RSA_F4>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_MT_CLIENT_CERTIFICATE

C<static method SSL2_MT_CLIENT_CERTIFICATE : int ();>

Returns the value of C<SSL2_MT_CLIENT_CERTIFICATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_MT_CLIENT_FINISHED

C<static method SSL2_MT_CLIENT_FINISHED : int ();>

Returns the value of C<SSL2_MT_CLIENT_FINISHED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_MT_CLIENT_HELLO

C<static method SSL2_MT_CLIENT_HELLO : int ();>

Returns the value of C<SSL2_MT_CLIENT_HELLO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_MT_CLIENT_MASTER_KEY

C<static method SSL2_MT_CLIENT_MASTER_KEY : int ();>

Returns the value of C<SSL2_MT_CLIENT_MASTER_KEY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_MT_ERROR

C<static method SSL2_MT_ERROR : int ();>

Returns the value of C<SSL2_MT_ERROR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_MT_REQUEST_CERTIFICATE

C<static method SSL2_MT_REQUEST_CERTIFICATE : int ();>

Returns the value of C<SSL2_MT_REQUEST_CERTIFICATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_MT_SERVER_FINISHED

C<static method SSL2_MT_SERVER_FINISHED : int ();>

Returns the value of C<SSL2_MT_SERVER_FINISHED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_MT_SERVER_HELLO

C<static method SSL2_MT_SERVER_HELLO : int ();>

Returns the value of C<SSL2_MT_SERVER_HELLO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_MT_SERVER_VERIFY

C<static method SSL2_MT_SERVER_VERIFY : int ();>

Returns the value of C<SSL2_MT_SERVER_VERIFY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL2_VERSION

C<static method SSL2_VERSION : int ();>

Returns the value of C<SSL2_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_CCS

C<static method SSL3_MT_CCS : int ();>

Returns the value of C<SSL3_MT_CCS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_CERTIFICATE

C<static method SSL3_MT_CERTIFICATE : int ();>

Returns the value of C<SSL3_MT_CERTIFICATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_CERTIFICATE_REQUEST

C<static method SSL3_MT_CERTIFICATE_REQUEST : int ();>

Returns the value of C<SSL3_MT_CERTIFICATE_REQUEST>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_CERTIFICATE_STATUS

C<static method SSL3_MT_CERTIFICATE_STATUS : int ();>

Returns the value of C<SSL3_MT_CERTIFICATE_STATUS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_CERTIFICATE_URL

C<static method SSL3_MT_CERTIFICATE_URL : int ();>

Returns the value of C<SSL3_MT_CERTIFICATE_URL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_CERTIFICATE_VERIFY

C<static method SSL3_MT_CERTIFICATE_VERIFY : int ();>

Returns the value of C<SSL3_MT_CERTIFICATE_VERIFY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_CHANGE_CIPHER_SPEC

C<static method SSL3_MT_CHANGE_CIPHER_SPEC : int ();>

Returns the value of C<SSL3_MT_CHANGE_CIPHER_SPEC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_CLIENT_HELLO

C<static method SSL3_MT_CLIENT_HELLO : int ();>

Returns the value of C<SSL3_MT_CLIENT_HELLO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_CLIENT_KEY_EXCHANGE

C<static method SSL3_MT_CLIENT_KEY_EXCHANGE : int ();>

Returns the value of C<SSL3_MT_CLIENT_KEY_EXCHANGE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_ENCRYPTED_EXTENSIONS

C<static method SSL3_MT_ENCRYPTED_EXTENSIONS : int ();>

Returns the value of C<SSL3_MT_ENCRYPTED_EXTENSIONS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_END_OF_EARLY_DATA

C<static method SSL3_MT_END_OF_EARLY_DATA : int ();>

Returns the value of C<SSL3_MT_END_OF_EARLY_DATA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_FINISHED

C<static method SSL3_MT_FINISHED : int ();>

Returns the value of C<SSL3_MT_FINISHED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_HELLO_REQUEST

C<static method SSL3_MT_HELLO_REQUEST : int ();>

Returns the value of C<SSL3_MT_HELLO_REQUEST>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_KEY_UPDATE

C<static method SSL3_MT_KEY_UPDATE : int ();>

Returns the value of C<SSL3_MT_KEY_UPDATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_MESSAGE_HASH

C<static method SSL3_MT_MESSAGE_HASH : int ();>

Returns the value of C<SSL3_MT_MESSAGE_HASH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_NEWSESSION_TICKET

C<static method SSL3_MT_NEWSESSION_TICKET : int ();>

Returns the value of C<SSL3_MT_NEWSESSION_TICKET>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_NEXT_PROTO

C<static method SSL3_MT_NEXT_PROTO : int ();>

Returns the value of C<SSL3_MT_NEXT_PROTO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_SERVER_DONE

C<static method SSL3_MT_SERVER_DONE : int ();>

Returns the value of C<SSL3_MT_SERVER_DONE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_SERVER_HELLO

C<static method SSL3_MT_SERVER_HELLO : int ();>

Returns the value of C<SSL3_MT_SERVER_HELLO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_SERVER_KEY_EXCHANGE

C<static method SSL3_MT_SERVER_KEY_EXCHANGE : int ();>

Returns the value of C<SSL3_MT_SERVER_KEY_EXCHANGE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_MT_SUPPLEMENTAL_DATA

C<static method SSL3_MT_SUPPLEMENTAL_DATA : int ();>

Returns the value of C<SSL3_MT_SUPPLEMENTAL_DATA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_RT_ALERT

C<static method SSL3_RT_ALERT : int ();>

Returns the value of C<SSL3_RT_ALERT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_RT_APPLICATION_DATA

C<static method SSL3_RT_APPLICATION_DATA : int ();>

Returns the value of C<SSL3_RT_APPLICATION_DATA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_RT_CHANGE_CIPHER_SPEC

C<static method SSL3_RT_CHANGE_CIPHER_SPEC : int ();>

Returns the value of C<SSL3_RT_CHANGE_CIPHER_SPEC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_RT_HANDSHAKE

C<static method SSL3_RT_HANDSHAKE : int ();>

Returns the value of C<SSL3_RT_HANDSHAKE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_RT_HEADER

C<static method SSL3_RT_HEADER : int ();>

Returns the value of C<SSL3_RT_HEADER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_RT_INNER_CONTENT_TYPE

C<static method SSL3_RT_INNER_CONTENT_TYPE : int ();>

Returns the value of C<SSL3_RT_INNER_CONTENT_TYPE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL3_VERSION

C<static method SSL3_VERSION : int ();>

Returns the value of C<SSL3_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSLEAY_BUILT_ON

C<static method SSLEAY_BUILT_ON : int ();>

Returns the value of C<SSLEAY_BUILT_ON>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSLEAY_CFLAGS

C<static method SSLEAY_CFLAGS : int ();>

Returns the value of C<SSLEAY_CFLAGS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSLEAY_DIR

C<static method SSLEAY_DIR : int ();>

Returns the value of C<SSLEAY_DIR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSLEAY_PLATFORM

C<static method SSLEAY_PLATFORM : int ();>

Returns the value of C<SSLEAY_PLATFORM>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSLEAY_VERSION

C<static method SSLEAY_VERSION : int ();>

Returns the value of C<SSLEAY_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_ACCEPT_EXIT

C<static method SSL_CB_ACCEPT_EXIT : int ();>

Returns the value of C<SSL_CB_ACCEPT_EXIT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_ACCEPT_LOOP

C<static method SSL_CB_ACCEPT_LOOP : int ();>

Returns the value of C<SSL_CB_ACCEPT_LOOP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_ALERT

C<static method SSL_CB_ALERT : int ();>

Returns the value of C<SSL_CB_ALERT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_CONNECT_EXIT

C<static method SSL_CB_CONNECT_EXIT : int ();>

Returns the value of C<SSL_CB_CONNECT_EXIT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_CONNECT_LOOP

C<static method SSL_CB_CONNECT_LOOP : int ();>

Returns the value of C<SSL_CB_CONNECT_LOOP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_EXIT

C<static method SSL_CB_EXIT : int ();>

Returns the value of C<SSL_CB_EXIT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_HANDSHAKE_DONE

C<static method SSL_CB_HANDSHAKE_DONE : int ();>

Returns the value of C<SSL_CB_HANDSHAKE_DONE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_HANDSHAKE_START

C<static method SSL_CB_HANDSHAKE_START : int ();>

Returns the value of C<SSL_CB_HANDSHAKE_START>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_LOOP

C<static method SSL_CB_LOOP : int ();>

Returns the value of C<SSL_CB_LOOP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_READ

C<static method SSL_CB_READ : int ();>

Returns the value of C<SSL_CB_READ>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_READ_ALERT

C<static method SSL_CB_READ_ALERT : int ();>

Returns the value of C<SSL_CB_READ_ALERT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_WRITE

C<static method SSL_CB_WRITE : int ();>

Returns the value of C<SSL_CB_WRITE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_CB_WRITE_ALERT

C<static method SSL_CB_WRITE_ALERT : int ();>

Returns the value of C<SSL_CB_WRITE_ALERT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ERROR_NONE

C<static method SSL_ERROR_NONE : int ();>

Returns the value of C<SSL_ERROR_NONE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ERROR_SSL

C<static method SSL_ERROR_SSL : int ();>

Returns the value of C<SSL_ERROR_SSL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ERROR_SYSCALL

C<static method SSL_ERROR_SYSCALL : int ();>

Returns the value of C<SSL_ERROR_SYSCALL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ERROR_WANT_ACCEPT

C<static method SSL_ERROR_WANT_ACCEPT : int ();>

Returns the value of C<SSL_ERROR_WANT_ACCEPT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ERROR_WANT_CONNECT

C<static method SSL_ERROR_WANT_CONNECT : int ();>

Returns the value of C<SSL_ERROR_WANT_CONNECT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ERROR_WANT_READ

C<static method SSL_ERROR_WANT_READ : int ();>

Returns the value of C<SSL_ERROR_WANT_READ>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ERROR_WANT_WRITE

C<static method SSL_ERROR_WANT_WRITE : int ();>

Returns the value of C<SSL_ERROR_WANT_WRITE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ERROR_WANT_X509_LOOKUP

C<static method SSL_ERROR_WANT_X509_LOOKUP : int ();>

Returns the value of C<SSL_ERROR_WANT_X509_LOOKUP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ERROR_ZERO_RETURN

C<static method SSL_ERROR_ZERO_RETURN : int ();>

Returns the value of C<SSL_ERROR_ZERO_RETURN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_FILETYPE_ASN1

C<static method SSL_FILETYPE_ASN1 : int ();>

Returns the value of C<SSL_FILETYPE_ASN1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_FILETYPE_PEM

C<static method SSL_FILETYPE_PEM : int ();>

Returns the value of C<SSL_FILETYPE_PEM>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_CLIENT_CERTIFICATE

C<static method SSL_F_CLIENT_CERTIFICATE : int ();>

Returns the value of C<SSL_F_CLIENT_CERTIFICATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_CLIENT_HELLO

C<static method SSL_F_CLIENT_HELLO : int ();>

Returns the value of C<SSL_F_CLIENT_HELLO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_CLIENT_MASTER_KEY

C<static method SSL_F_CLIENT_MASTER_KEY : int ();>

Returns the value of C<SSL_F_CLIENT_MASTER_KEY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_D2I_SSL_SESSION

C<static method SSL_F_D2I_SSL_SESSION : int ();>

Returns the value of C<SSL_F_D2I_SSL_SESSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_GET_CLIENT_FINISHED

C<static method SSL_F_GET_CLIENT_FINISHED : int ();>

Returns the value of C<SSL_F_GET_CLIENT_FINISHED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_GET_CLIENT_HELLO

C<static method SSL_F_GET_CLIENT_HELLO : int ();>

Returns the value of C<SSL_F_GET_CLIENT_HELLO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_GET_CLIENT_MASTER_KEY

C<static method SSL_F_GET_CLIENT_MASTER_KEY : int ();>

Returns the value of C<SSL_F_GET_CLIENT_MASTER_KEY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_GET_SERVER_FINISHED

C<static method SSL_F_GET_SERVER_FINISHED : int ();>

Returns the value of C<SSL_F_GET_SERVER_FINISHED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_GET_SERVER_HELLO

C<static method SSL_F_GET_SERVER_HELLO : int ();>

Returns the value of C<SSL_F_GET_SERVER_HELLO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_GET_SERVER_VERIFY

C<static method SSL_F_GET_SERVER_VERIFY : int ();>

Returns the value of C<SSL_F_GET_SERVER_VERIFY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_I2D_SSL_SESSION

C<static method SSL_F_I2D_SSL_SESSION : int ();>

Returns the value of C<SSL_F_I2D_SSL_SESSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_READ_N

C<static method SSL_F_READ_N : int ();>

Returns the value of C<SSL_F_READ_N>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_REQUEST_CERTIFICATE

C<static method SSL_F_REQUEST_CERTIFICATE : int ();>

Returns the value of C<SSL_F_REQUEST_CERTIFICATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SERVER_HELLO

C<static method SSL_F_SERVER_HELLO : int ();>

Returns the value of C<SSL_F_SERVER_HELLO>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_CERT_NEW

C<static method SSL_F_SSL_CERT_NEW : int ();>

Returns the value of C<SSL_F_SSL_CERT_NEW>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_GET_NEW_SESSION

C<static method SSL_F_SSL_GET_NEW_SESSION : int ();>

Returns the value of C<SSL_F_SSL_GET_NEW_SESSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_NEW

C<static method SSL_F_SSL_NEW : int ();>

Returns the value of C<SSL_F_SSL_NEW>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_READ

C<static method SSL_F_SSL_READ : int ();>

Returns the value of C<SSL_F_SSL_READ>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_RSA_PRIVATE_DECRYPT

C<static method SSL_F_SSL_RSA_PRIVATE_DECRYPT : int ();>

Returns the value of C<SSL_F_SSL_RSA_PRIVATE_DECRYPT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_RSA_PUBLIC_ENCRYPT

C<static method SSL_F_SSL_RSA_PUBLIC_ENCRYPT : int ();>

Returns the value of C<SSL_F_SSL_RSA_PUBLIC_ENCRYPT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_SESSION_NEW

C<static method SSL_F_SSL_SESSION_NEW : int ();>

Returns the value of C<SSL_F_SSL_SESSION_NEW>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_SESSION_PRINT_FP

C<static method SSL_F_SSL_SESSION_PRINT_FP : int ();>

Returns the value of C<SSL_F_SSL_SESSION_PRINT_FP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_SET_FD

C<static method SSL_F_SSL_SET_FD : int ();>

Returns the value of C<SSL_F_SSL_SET_FD>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_SET_RFD

C<static method SSL_F_SSL_SET_RFD : int ();>

Returns the value of C<SSL_F_SSL_SET_RFD>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_SET_WFD

C<static method SSL_F_SSL_SET_WFD : int ();>

Returns the value of C<SSL_F_SSL_SET_WFD>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_USE_CERTIFICATE

C<static method SSL_F_SSL_USE_CERTIFICATE : int ();>

Returns the value of C<SSL_F_SSL_USE_CERTIFICATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_USE_CERTIFICATE_ASN1

C<static method SSL_F_SSL_USE_CERTIFICATE_ASN1 : int ();>

Returns the value of C<SSL_F_SSL_USE_CERTIFICATE_ASN1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_USE_CERTIFICATE_FILE

C<static method SSL_F_SSL_USE_CERTIFICATE_FILE : int ();>

Returns the value of C<SSL_F_SSL_USE_CERTIFICATE_FILE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_USE_PRIVATEKEY

C<static method SSL_F_SSL_USE_PRIVATEKEY : int ();>

Returns the value of C<SSL_F_SSL_USE_PRIVATEKEY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_USE_PRIVATEKEY_ASN1

C<static method SSL_F_SSL_USE_PRIVATEKEY_ASN1 : int ();>

Returns the value of C<SSL_F_SSL_USE_PRIVATEKEY_ASN1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_USE_PRIVATEKEY_FILE

C<static method SSL_F_SSL_USE_PRIVATEKEY_FILE : int ();>

Returns the value of C<SSL_F_SSL_USE_PRIVATEKEY_FILE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_USE_RSAPRIVATEKEY

C<static method SSL_F_SSL_USE_RSAPRIVATEKEY : int ();>

Returns the value of C<SSL_F_SSL_USE_RSAPRIVATEKEY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_USE_RSAPRIVATEKEY_ASN1

C<static method SSL_F_SSL_USE_RSAPRIVATEKEY_ASN1 : int ();>

Returns the value of C<SSL_F_SSL_USE_RSAPRIVATEKEY_ASN1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_SSL_USE_RSAPRIVATEKEY_FILE

C<static method SSL_F_SSL_USE_RSAPRIVATEKEY_FILE : int ();>

Returns the value of C<SSL_F_SSL_USE_RSAPRIVATEKEY_FILE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_F_WRITE_PENDING

C<static method SSL_F_WRITE_PENDING : int ();>

Returns the value of C<SSL_F_WRITE_PENDING>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_MIN_RSA_MODULUS_LENGTH_IN_BYTES

C<static method SSL_MIN_RSA_MODULUS_LENGTH_IN_BYTES : int ();>

Returns the value of C<SSL_MIN_RSA_MODULUS_LENGTH_IN_BYTES>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER

C<static method SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER : int ();>

Returns the value of C<SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_MODE_AUTO_RETRY

C<static method SSL_MODE_AUTO_RETRY : int ();>

Returns the value of C<SSL_MODE_AUTO_RETRY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_MODE_ENABLE_PARTIAL_WRITE

C<static method SSL_MODE_ENABLE_PARTIAL_WRITE : int ();>

Returns the value of C<SSL_MODE_ENABLE_PARTIAL_WRITE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_MODE_RELEASE_BUFFERS

C<static method SSL_MODE_RELEASE_BUFFERS : int ();>

Returns the value of C<SSL_MODE_RELEASE_BUFFERS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_NOTHING

C<static method SSL_NOTHING : int ();>

Returns the value of C<SSL_NOTHING>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_ALL

C<static method SSL_OP_ALL : int ();>

Returns the value of C<SSL_OP_ALL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_ALLOW_NO_DHE_KEX

C<static method SSL_OP_ALLOW_NO_DHE_KEX : int ();>

Returns the value of C<SSL_OP_ALLOW_NO_DHE_KEX>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION

C<static method SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION : int ();>

Returns the value of C<SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_CIPHER_SERVER_PREFERENCE

C<static method SSL_OP_CIPHER_SERVER_PREFERENCE : int ();>

Returns the value of C<SSL_OP_CIPHER_SERVER_PREFERENCE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_CISCO_ANYCONNECT

C<static method SSL_OP_CISCO_ANYCONNECT : int ();>

Returns the value of C<SSL_OP_CISCO_ANYCONNECT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_COOKIE_EXCHANGE

C<static method SSL_OP_COOKIE_EXCHANGE : int ();>

Returns the value of C<SSL_OP_COOKIE_EXCHANGE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_CRYPTOPRO_TLSEXT_BUG

C<static method SSL_OP_CRYPTOPRO_TLSEXT_BUG : int ();>

Returns the value of C<SSL_OP_CRYPTOPRO_TLSEXT_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS

C<static method SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS : int ();>

Returns the value of C<SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_ENABLE_MIDDLEBOX_COMPAT

C<static method SSL_OP_ENABLE_MIDDLEBOX_COMPAT : int ();>

Returns the value of C<SSL_OP_ENABLE_MIDDLEBOX_COMPAT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_EPHEMERAL_RSA

C<static method SSL_OP_EPHEMERAL_RSA : int ();>

Returns the value of C<SSL_OP_EPHEMERAL_RSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_LEGACY_SERVER_CONNECT

C<static method SSL_OP_LEGACY_SERVER_CONNECT : int ();>

Returns the value of C<SSL_OP_LEGACY_SERVER_CONNECT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER

C<static method SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER : int ();>

Returns the value of C<SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_MICROSOFT_SESS_ID_BUG

C<static method SSL_OP_MICROSOFT_SESS_ID_BUG : int ();>

Returns the value of C<SSL_OP_MICROSOFT_SESS_ID_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_MSIE_SSLV2_RSA_PADDING

C<static method SSL_OP_MSIE_SSLV2_RSA_PADDING : int ();>

Returns the value of C<SSL_OP_MSIE_SSLV2_RSA_PADDING>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NETSCAPE_CA_DN_BUG

C<static method SSL_OP_NETSCAPE_CA_DN_BUG : int ();>

Returns the value of C<SSL_OP_NETSCAPE_CA_DN_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NETSCAPE_CHALLENGE_BUG

C<static method SSL_OP_NETSCAPE_CHALLENGE_BUG : int ();>

Returns the value of C<SSL_OP_NETSCAPE_CHALLENGE_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG

C<static method SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG : int ();>

Returns the value of C<SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG

C<static method SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG : int ();>

Returns the value of C<SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NON_EXPORT_FIRST

C<static method SSL_OP_NON_EXPORT_FIRST : int ();>

Returns the value of C<SSL_OP_NON_EXPORT_FIRST>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_ANTI_REPLAY

C<static method SSL_OP_NO_ANTI_REPLAY : int ();>

Returns the value of C<SSL_OP_NO_ANTI_REPLAY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_CLIENT_RENEGOTIATION

C<static method SSL_OP_NO_CLIENT_RENEGOTIATION : int ();>

Returns the value of C<SSL_OP_NO_CLIENT_RENEGOTIATION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_COMPRESSION

C<static method SSL_OP_NO_COMPRESSION : int ();>

Returns the value of C<SSL_OP_NO_COMPRESSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_ENCRYPT_THEN_MAC

C<static method SSL_OP_NO_ENCRYPT_THEN_MAC : int ();>

Returns the value of C<SSL_OP_NO_ENCRYPT_THEN_MAC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_QUERY_MTU

C<static method SSL_OP_NO_QUERY_MTU : int ();>

Returns the value of C<SSL_OP_NO_QUERY_MTU>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_RENEGOTIATION

C<static method SSL_OP_NO_RENEGOTIATION : int ();>

Returns the value of C<SSL_OP_NO_RENEGOTIATION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION

C<static method SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION : int ();>

Returns the value of C<SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_SSL_MASK

C<static method SSL_OP_NO_SSL_MASK : int ();>

Returns the value of C<SSL_OP_NO_SSL_MASK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_SSLv2

C<static method SSL_OP_NO_SSLv2 : int ();>

Returns the value of C<SSL_OP_NO_SSLv2>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_SSLv3

C<static method SSL_OP_NO_SSLv3 : int ();>

Returns the value of C<SSL_OP_NO_SSLv3>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_TICKET

C<static method SSL_OP_NO_TICKET : int ();>

Returns the value of C<SSL_OP_NO_TICKET>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_TLSv1

C<static method SSL_OP_NO_TLSv1 : int ();>

Returns the value of C<SSL_OP_NO_TLSv1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_TLSv1_1

C<static method SSL_OP_NO_TLSv1_1 : int ();>

Returns the value of C<SSL_OP_NO_TLSv1_1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_TLSv1_2

C<static method SSL_OP_NO_TLSv1_2 : int ();>

Returns the value of C<SSL_OP_NO_TLSv1_2>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_NO_TLSv1_3

C<static method SSL_OP_NO_TLSv1_3 : int ();>

Returns the value of C<SSL_OP_NO_TLSv1_3>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_PKCS1_CHECK_1

C<static method SSL_OP_PKCS1_CHECK_1 : int ();>

Returns the value of C<SSL_OP_PKCS1_CHECK_1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_PKCS1_CHECK_2

C<static method SSL_OP_PKCS1_CHECK_2 : int ();>

Returns the value of C<SSL_OP_PKCS1_CHECK_2>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_PRIORITIZE_CHACHA

C<static method SSL_OP_PRIORITIZE_CHACHA : int ();>

Returns the value of C<SSL_OP_PRIORITIZE_CHACHA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_SAFARI_ECDHE_ECDSA_BUG

C<static method SSL_OP_SAFARI_ECDHE_ECDSA_BUG : int ();>

Returns the value of C<SSL_OP_SAFARI_ECDHE_ECDSA_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_SINGLE_DH_USE

C<static method SSL_OP_SINGLE_DH_USE : int ();>

Returns the value of C<SSL_OP_SINGLE_DH_USE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_SINGLE_ECDH_USE

C<static method SSL_OP_SINGLE_ECDH_USE : int ();>

Returns the value of C<SSL_OP_SINGLE_ECDH_USE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_SSLEAY_080_CLIENT_DH_BUG

C<static method SSL_OP_SSLEAY_080_CLIENT_DH_BUG : int ();>

Returns the value of C<SSL_OP_SSLEAY_080_CLIENT_DH_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG

C<static method SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG : int ();>

Returns the value of C<SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_TLSEXT_PADDING

C<static method SSL_OP_TLSEXT_PADDING : int ();>

Returns the value of C<SSL_OP_TLSEXT_PADDING>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_TLS_BLOCK_PADDING_BUG

C<static method SSL_OP_TLS_BLOCK_PADDING_BUG : int ();>

Returns the value of C<SSL_OP_TLS_BLOCK_PADDING_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_TLS_D5_BUG

C<static method SSL_OP_TLS_D5_BUG : int ();>

Returns the value of C<SSL_OP_TLS_D5_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_OP_TLS_ROLLBACK_BUG

C<static method SSL_OP_TLS_ROLLBACK_BUG : int ();>

Returns the value of C<SSL_OP_TLS_ROLLBACK_BUG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_READING

C<static method SSL_READING : int ();>

Returns the value of C<SSL_READING>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_RECEIVED_SHUTDOWN

C<static method SSL_RECEIVED_SHUTDOWN : int ();>

Returns the value of C<SSL_RECEIVED_SHUTDOWN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_BAD_AUTHENTICATION_TYPE

C<static method SSL_R_BAD_AUTHENTICATION_TYPE : int ();>

Returns the value of C<SSL_R_BAD_AUTHENTICATION_TYPE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_BAD_CHECKSUM

C<static method SSL_R_BAD_CHECKSUM : int ();>

Returns the value of C<SSL_R_BAD_CHECKSUM>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_BAD_MAC_DECODE

C<static method SSL_R_BAD_MAC_DECODE : int ();>

Returns the value of C<SSL_R_BAD_MAC_DECODE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_BAD_RESPONSE_ARGUMENT

C<static method SSL_R_BAD_RESPONSE_ARGUMENT : int ();>

Returns the value of C<SSL_R_BAD_RESPONSE_ARGUMENT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_BAD_SSL_FILETYPE

C<static method SSL_R_BAD_SSL_FILETYPE : int ();>

Returns the value of C<SSL_R_BAD_SSL_FILETYPE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_BAD_SSL_SESSION_ID_LENGTH

C<static method SSL_R_BAD_SSL_SESSION_ID_LENGTH : int ();>

Returns the value of C<SSL_R_BAD_SSL_SESSION_ID_LENGTH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_BAD_STATE

C<static method SSL_R_BAD_STATE : int ();>

Returns the value of C<SSL_R_BAD_STATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_BAD_WRITE_RETRY

C<static method SSL_R_BAD_WRITE_RETRY : int ();>

Returns the value of C<SSL_R_BAD_WRITE_RETRY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_CHALLENGE_IS_DIFFERENT

C<static method SSL_R_CHALLENGE_IS_DIFFERENT : int ();>

Returns the value of C<SSL_R_CHALLENGE_IS_DIFFERENT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_CIPHER_TABLE_SRC_ERROR

C<static method SSL_R_CIPHER_TABLE_SRC_ERROR : int ();>

Returns the value of C<SSL_R_CIPHER_TABLE_SRC_ERROR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_INVALID_CHALLENGE_LENGTH

C<static method SSL_R_INVALID_CHALLENGE_LENGTH : int ();>

Returns the value of C<SSL_R_INVALID_CHALLENGE_LENGTH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_NO_CERTIFICATE_SET

C<static method SSL_R_NO_CERTIFICATE_SET : int ();>

Returns the value of C<SSL_R_NO_CERTIFICATE_SET>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_NO_CERTIFICATE_SPECIFIED

C<static method SSL_R_NO_CERTIFICATE_SPECIFIED : int ();>

Returns the value of C<SSL_R_NO_CERTIFICATE_SPECIFIED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_NO_CIPHER_LIST

C<static method SSL_R_NO_CIPHER_LIST : int ();>

Returns the value of C<SSL_R_NO_CIPHER_LIST>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_NO_CIPHER_MATCH

C<static method SSL_R_NO_CIPHER_MATCH : int ();>

Returns the value of C<SSL_R_NO_CIPHER_MATCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_NO_PRIVATEKEY

C<static method SSL_R_NO_PRIVATEKEY : int ();>

Returns the value of C<SSL_R_NO_PRIVATEKEY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_NO_PUBLICKEY

C<static method SSL_R_NO_PUBLICKEY : int ();>

Returns the value of C<SSL_R_NO_PUBLICKEY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_NULL_SSL_CTX

C<static method SSL_R_NULL_SSL_CTX : int ();>

Returns the value of C<SSL_R_NULL_SSL_CTX>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_PEER_DID_NOT_RETURN_A_CERTIFICATE

C<static method SSL_R_PEER_DID_NOT_RETURN_A_CERTIFICATE : int ();>

Returns the value of C<SSL_R_PEER_DID_NOT_RETURN_A_CERTIFICATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_PEER_ERROR

C<static method SSL_R_PEER_ERROR : int ();>

Returns the value of C<SSL_R_PEER_ERROR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_PEER_ERROR_CERTIFICATE

C<static method SSL_R_PEER_ERROR_CERTIFICATE : int ();>

Returns the value of C<SSL_R_PEER_ERROR_CERTIFICATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_PEER_ERROR_NO_CIPHER

C<static method SSL_R_PEER_ERROR_NO_CIPHER : int ();>

Returns the value of C<SSL_R_PEER_ERROR_NO_CIPHER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE

C<static method SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE : int ();>

Returns the value of C<SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_PUBLIC_KEY_ENCRYPT_ERROR

C<static method SSL_R_PUBLIC_KEY_ENCRYPT_ERROR : int ();>

Returns the value of C<SSL_R_PUBLIC_KEY_ENCRYPT_ERROR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_PUBLIC_KEY_IS_NOT_RSA

C<static method SSL_R_PUBLIC_KEY_IS_NOT_RSA : int ();>

Returns the value of C<SSL_R_PUBLIC_KEY_IS_NOT_RSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_READ_WRONG_PACKET_TYPE

C<static method SSL_R_READ_WRONG_PACKET_TYPE : int ();>

Returns the value of C<SSL_R_READ_WRONG_PACKET_TYPE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_SHORT_READ

C<static method SSL_R_SHORT_READ : int ();>

Returns the value of C<SSL_R_SHORT_READ>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_SSL_SESSION_ID_IS_DIFFERENT

C<static method SSL_R_SSL_SESSION_ID_IS_DIFFERENT : int ();>

Returns the value of C<SSL_R_SSL_SESSION_ID_IS_DIFFERENT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_UNABLE_TO_EXTRACT_PUBLIC_KEY

C<static method SSL_R_UNABLE_TO_EXTRACT_PUBLIC_KEY : int ();>

Returns the value of C<SSL_R_UNABLE_TO_EXTRACT_PUBLIC_KEY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_UNKNOWN_REMOTE_ERROR_TYPE

C<static method SSL_R_UNKNOWN_REMOTE_ERROR_TYPE : int ();>

Returns the value of C<SSL_R_UNKNOWN_REMOTE_ERROR_TYPE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_UNKNOWN_STATE

C<static method SSL_R_UNKNOWN_STATE : int ();>

Returns the value of C<SSL_R_UNKNOWN_STATE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_R_X509_LIB

C<static method SSL_R_X509_LIB : int ();>

Returns the value of C<SSL_R_X509_LIB>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SENT_SHUTDOWN

C<static method SSL_SENT_SHUTDOWN : int ();>

Returns the value of C<SSL_SENT_SHUTDOWN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SESSION_ASN1_VERSION

C<static method SSL_SESSION_ASN1_VERSION : int ();>

Returns the value of C<SSL_SESSION_ASN1_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SESS_CACHE_BOTH

C<static method SSL_SESS_CACHE_BOTH : int ();>

Returns the value of C<SSL_SESS_CACHE_BOTH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SESS_CACHE_CLIENT

C<static method SSL_SESS_CACHE_CLIENT : int ();>

Returns the value of C<SSL_SESS_CACHE_CLIENT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SESS_CACHE_NO_AUTO_CLEAR

C<static method SSL_SESS_CACHE_NO_AUTO_CLEAR : int ();>

Returns the value of C<SSL_SESS_CACHE_NO_AUTO_CLEAR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SESS_CACHE_NO_INTERNAL

C<static method SSL_SESS_CACHE_NO_INTERNAL : int ();>

Returns the value of C<SSL_SESS_CACHE_NO_INTERNAL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SESS_CACHE_NO_INTERNAL_LOOKUP

C<static method SSL_SESS_CACHE_NO_INTERNAL_LOOKUP : int ();>

Returns the value of C<SSL_SESS_CACHE_NO_INTERNAL_LOOKUP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SESS_CACHE_NO_INTERNAL_STORE

C<static method SSL_SESS_CACHE_NO_INTERNAL_STORE : int ();>

Returns the value of C<SSL_SESS_CACHE_NO_INTERNAL_STORE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SESS_CACHE_OFF

C<static method SSL_SESS_CACHE_OFF : int ();>

Returns the value of C<SSL_SESS_CACHE_OFF>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_SESS_CACHE_SERVER

C<static method SSL_SESS_CACHE_SERVER : int ();>

Returns the value of C<SSL_SESS_CACHE_SERVER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ST_ACCEPT

C<static method SSL_ST_ACCEPT : int ();>

Returns the value of C<SSL_ST_ACCEPT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ST_BEFORE

C<static method SSL_ST_BEFORE : int ();>

Returns the value of C<SSL_ST_BEFORE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ST_CONNECT

C<static method SSL_ST_CONNECT : int ();>

Returns the value of C<SSL_ST_CONNECT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ST_INIT

C<static method SSL_ST_INIT : int ();>

Returns the value of C<SSL_ST_INIT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ST_OK

C<static method SSL_ST_OK : int ();>

Returns the value of C<SSL_ST_OK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ST_READ_BODY

C<static method SSL_ST_READ_BODY : int ();>

Returns the value of C<SSL_ST_READ_BODY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_ST_READ_HEADER

C<static method SSL_ST_READ_HEADER : int ();>

Returns the value of C<SSL_ST_READ_HEADER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_VERIFY_CLIENT_ONCE

C<static method SSL_VERIFY_CLIENT_ONCE : int ();>

Returns the value of C<SSL_VERIFY_CLIENT_ONCE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_VERIFY_FAIL_IF_NO_PEER_CERT

C<static method SSL_VERIFY_FAIL_IF_NO_PEER_CERT : int ();>

Returns the value of C<SSL_VERIFY_FAIL_IF_NO_PEER_CERT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_VERIFY_NONE

C<static method SSL_VERIFY_NONE : int ();>

Returns the value of C<SSL_VERIFY_NONE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_VERIFY_PEER

C<static method SSL_VERIFY_PEER : int ();>

Returns the value of C<SSL_VERIFY_PEER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_VERIFY_POST_HANDSHAKE

C<static method SSL_VERIFY_POST_HANDSHAKE : int ();>

Returns the value of C<SSL_VERIFY_POST_HANDSHAKE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_WRITING

C<static method SSL_WRITING : int ();>

Returns the value of C<SSL_WRITING>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_X509_LOOKUP

C<static method SSL_X509_LOOKUP : int ();>

Returns the value of C<SSL_X509_LOOKUP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TLS1_1_VERSION

C<static method TLS1_1_VERSION : int ();>

Returns the value of C<TLS1_1_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TLS1_2_VERSION

C<static method TLS1_2_VERSION : int ();>

Returns the value of C<TLS1_2_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TLS1_3_VERSION

C<static method TLS1_3_VERSION : int ();>

Returns the value of C<TLS1_3_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TLS1_VERSION

C<static method TLS1_VERSION : int ();>

Returns the value of C<TLS1_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TLSEXT_STATUSTYPE_ocsp

C<static method TLSEXT_STATUSTYPE_ocsp : int ();>

Returns the value of C<TLSEXT_STATUSTYPE_ocsp>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 V_OCSP_CERTSTATUS_GOOD

C<static method V_OCSP_CERTSTATUS_GOOD : int ();>

Returns the value of C<V_OCSP_CERTSTATUS_GOOD>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 V_OCSP_CERTSTATUS_REVOKED

C<static method V_OCSP_CERTSTATUS_REVOKED : int ();>

Returns the value of C<V_OCSP_CERTSTATUS_REVOKED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 V_OCSP_CERTSTATUS_UNKNOWN

C<static method V_OCSP_CERTSTATUS_UNKNOWN : int ();>

Returns the value of C<V_OCSP_CERTSTATUS_UNKNOWN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT

C<static method X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT : int ();>

Returns the value of C<X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_CHECK_FLAG_MULTI_LABEL_WILDCARDS

C<static method X509_CHECK_FLAG_MULTI_LABEL_WILDCARDS : int ();>

Returns the value of C<X509_CHECK_FLAG_MULTI_LABEL_WILDCARDS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_CHECK_FLAG_NEVER_CHECK_SUBJECT

C<static method X509_CHECK_FLAG_NEVER_CHECK_SUBJECT : int ();>

Returns the value of C<X509_CHECK_FLAG_NEVER_CHECK_SUBJECT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS

C<static method X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS : int ();>

Returns the value of C<X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_CHECK_FLAG_NO_WILDCARDS

C<static method X509_CHECK_FLAG_NO_WILDCARDS : int ();>

Returns the value of C<X509_CHECK_FLAG_NO_WILDCARDS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS

C<static method X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS : int ();>

Returns the value of C<X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_FILETYPE_ASN1

C<static method X509_FILETYPE_ASN1 : int ();>

Returns the value of C<X509_FILETYPE_ASN1>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_FILETYPE_DEFAULT

C<static method X509_FILETYPE_DEFAULT : int ();>

Returns the value of C<X509_FILETYPE_DEFAULT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_FILETYPE_PEM

C<static method X509_FILETYPE_PEM : int ();>

Returns the value of C<X509_FILETYPE_PEM>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_PURPOSE_ANY

C<static method X509_PURPOSE_ANY : int ();>

Returns the value of C<X509_PURPOSE_ANY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_PURPOSE_CRL_SIGN

C<static method X509_PURPOSE_CRL_SIGN : int ();>

Returns the value of C<X509_PURPOSE_CRL_SIGN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_PURPOSE_NS_SSL_SERVER

C<static method X509_PURPOSE_NS_SSL_SERVER : int ();>

Returns the value of C<X509_PURPOSE_NS_SSL_SERVER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_PURPOSE_OCSP_HELPER

C<static method X509_PURPOSE_OCSP_HELPER : int ();>

Returns the value of C<X509_PURPOSE_OCSP_HELPER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_PURPOSE_SMIME_ENCRYPT

C<static method X509_PURPOSE_SMIME_ENCRYPT : int ();>

Returns the value of C<X509_PURPOSE_SMIME_ENCRYPT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_PURPOSE_SMIME_SIGN

C<static method X509_PURPOSE_SMIME_SIGN : int ();>

Returns the value of C<X509_PURPOSE_SMIME_SIGN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_PURPOSE_SSL_CLIENT

C<static method X509_PURPOSE_SSL_CLIENT : int ();>

Returns the value of C<X509_PURPOSE_SSL_CLIENT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_PURPOSE_SSL_SERVER

C<static method X509_PURPOSE_SSL_SERVER : int ();>

Returns the value of C<X509_PURPOSE_SSL_SERVER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_PURPOSE_TIMESTAMP_SIGN

C<static method X509_PURPOSE_TIMESTAMP_SIGN : int ();>

Returns the value of C<X509_PURPOSE_TIMESTAMP_SIGN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_TRUST_COMPAT

C<static method X509_TRUST_COMPAT : int ();>

Returns the value of C<X509_TRUST_COMPAT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_TRUST_EMAIL

C<static method X509_TRUST_EMAIL : int ();>

Returns the value of C<X509_TRUST_EMAIL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_TRUST_OBJECT_SIGN

C<static method X509_TRUST_OBJECT_SIGN : int ();>

Returns the value of C<X509_TRUST_OBJECT_SIGN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_TRUST_OCSP_REQUEST

C<static method X509_TRUST_OCSP_REQUEST : int ();>

Returns the value of C<X509_TRUST_OCSP_REQUEST>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_TRUST_OCSP_SIGN

C<static method X509_TRUST_OCSP_SIGN : int ();>

Returns the value of C<X509_TRUST_OCSP_SIGN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_TRUST_SSL_CLIENT

C<static method X509_TRUST_SSL_CLIENT : int ();>

Returns the value of C<X509_TRUST_SSL_CLIENT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_TRUST_SSL_SERVER

C<static method X509_TRUST_SSL_SERVER : int ();>

Returns the value of C<X509_TRUST_SSL_SERVER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_TRUST_TSA

C<static method X509_TRUST_TSA : int ();>

Returns the value of C<X509_TRUST_TSA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH

C<static method X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH : int ();>

Returns the value of C<X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_AKID_SKID_MISMATCH

C<static method X509_V_ERR_AKID_SKID_MISMATCH : int ();>

Returns the value of C<X509_V_ERR_AKID_SKID_MISMATCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_APPLICATION_VERIFICATION

C<static method X509_V_ERR_APPLICATION_VERIFICATION : int ();>

Returns the value of C<X509_V_ERR_APPLICATION_VERIFICATION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CA_KEY_TOO_SMALL

C<static method X509_V_ERR_CA_KEY_TOO_SMALL : int ();>

Returns the value of C<X509_V_ERR_CA_KEY_TOO_SMALL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CA_MD_TOO_WEAK

C<static method X509_V_ERR_CA_MD_TOO_WEAK : int ();>

Returns the value of C<X509_V_ERR_CA_MD_TOO_WEAK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CERT_CHAIN_TOO_LONG

C<static method X509_V_ERR_CERT_CHAIN_TOO_LONG : int ();>

Returns the value of C<X509_V_ERR_CERT_CHAIN_TOO_LONG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CERT_HAS_EXPIRED

C<static method X509_V_ERR_CERT_HAS_EXPIRED : int ();>

Returns the value of C<X509_V_ERR_CERT_HAS_EXPIRED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CERT_NOT_YET_VALID

C<static method X509_V_ERR_CERT_NOT_YET_VALID : int ();>

Returns the value of C<X509_V_ERR_CERT_NOT_YET_VALID>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CERT_REJECTED

C<static method X509_V_ERR_CERT_REJECTED : int ();>

Returns the value of C<X509_V_ERR_CERT_REJECTED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CERT_REVOKED

C<static method X509_V_ERR_CERT_REVOKED : int ();>

Returns the value of C<X509_V_ERR_CERT_REVOKED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CERT_SIGNATURE_FAILURE

C<static method X509_V_ERR_CERT_SIGNATURE_FAILURE : int ();>

Returns the value of C<X509_V_ERR_CERT_SIGNATURE_FAILURE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CERT_UNTRUSTED

C<static method X509_V_ERR_CERT_UNTRUSTED : int ();>

Returns the value of C<X509_V_ERR_CERT_UNTRUSTED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CRL_HAS_EXPIRED

C<static method X509_V_ERR_CRL_HAS_EXPIRED : int ();>

Returns the value of C<X509_V_ERR_CRL_HAS_EXPIRED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CRL_NOT_YET_VALID

C<static method X509_V_ERR_CRL_NOT_YET_VALID : int ();>

Returns the value of C<X509_V_ERR_CRL_NOT_YET_VALID>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CRL_PATH_VALIDATION_ERROR

C<static method X509_V_ERR_CRL_PATH_VALIDATION_ERROR : int ();>

Returns the value of C<X509_V_ERR_CRL_PATH_VALIDATION_ERROR>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_CRL_SIGNATURE_FAILURE

C<static method X509_V_ERR_CRL_SIGNATURE_FAILURE : int ();>

Returns the value of C<X509_V_ERR_CRL_SIGNATURE_FAILURE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_DANE_NO_MATCH

C<static method X509_V_ERR_DANE_NO_MATCH : int ();>

Returns the value of C<X509_V_ERR_DANE_NO_MATCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT

C<static method X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT : int ();>

Returns the value of C<X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_DIFFERENT_CRL_SCOPE

C<static method X509_V_ERR_DIFFERENT_CRL_SCOPE : int ();>

Returns the value of C<X509_V_ERR_DIFFERENT_CRL_SCOPE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_EE_KEY_TOO_SMALL

C<static method X509_V_ERR_EE_KEY_TOO_SMALL : int ();>

Returns the value of C<X509_V_ERR_EE_KEY_TOO_SMALL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_EMAIL_MISMATCH

C<static method X509_V_ERR_EMAIL_MISMATCH : int ();>

Returns the value of C<X509_V_ERR_EMAIL_MISMATCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD

C<static method X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD : int ();>

Returns the value of C<X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD

C<static method X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD : int ();>

Returns the value of C<X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD

C<static method X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD : int ();>

Returns the value of C<X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD

C<static method X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD : int ();>

Returns the value of C<X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_EXCLUDED_VIOLATION

C<static method X509_V_ERR_EXCLUDED_VIOLATION : int ();>

Returns the value of C<X509_V_ERR_EXCLUDED_VIOLATION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_HOSTNAME_MISMATCH

C<static method X509_V_ERR_HOSTNAME_MISMATCH : int ();>

Returns the value of C<X509_V_ERR_HOSTNAME_MISMATCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_INVALID_CA

C<static method X509_V_ERR_INVALID_CA : int ();>

Returns the value of C<X509_V_ERR_INVALID_CA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_INVALID_CALL

C<static method X509_V_ERR_INVALID_CALL : int ();>

Returns the value of C<X509_V_ERR_INVALID_CALL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_INVALID_EXTENSION

C<static method X509_V_ERR_INVALID_EXTENSION : int ();>

Returns the value of C<X509_V_ERR_INVALID_EXTENSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_INVALID_NON_CA

C<static method X509_V_ERR_INVALID_NON_CA : int ();>

Returns the value of C<X509_V_ERR_INVALID_NON_CA>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_INVALID_POLICY_EXTENSION

C<static method X509_V_ERR_INVALID_POLICY_EXTENSION : int ();>

Returns the value of C<X509_V_ERR_INVALID_POLICY_EXTENSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_INVALID_PURPOSE

C<static method X509_V_ERR_INVALID_PURPOSE : int ();>

Returns the value of C<X509_V_ERR_INVALID_PURPOSE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_IP_ADDRESS_MISMATCH

C<static method X509_V_ERR_IP_ADDRESS_MISMATCH : int ();>

Returns the value of C<X509_V_ERR_IP_ADDRESS_MISMATCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_KEYUSAGE_NO_CERTSIGN

C<static method X509_V_ERR_KEYUSAGE_NO_CERTSIGN : int ();>

Returns the value of C<X509_V_ERR_KEYUSAGE_NO_CERTSIGN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_KEYUSAGE_NO_CRL_SIGN

C<static method X509_V_ERR_KEYUSAGE_NO_CRL_SIGN : int ();>

Returns the value of C<X509_V_ERR_KEYUSAGE_NO_CRL_SIGN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE

C<static method X509_V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE : int ();>

Returns the value of C<X509_V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_NO_EXPLICIT_POLICY

C<static method X509_V_ERR_NO_EXPLICIT_POLICY : int ();>

Returns the value of C<X509_V_ERR_NO_EXPLICIT_POLICY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_NO_VALID_SCTS

C<static method X509_V_ERR_NO_VALID_SCTS : int ();>

Returns the value of C<X509_V_ERR_NO_VALID_SCTS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_OCSP_CERT_UNKNOWN

C<static method X509_V_ERR_OCSP_CERT_UNKNOWN : int ();>

Returns the value of C<X509_V_ERR_OCSP_CERT_UNKNOWN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_OCSP_VERIFY_FAILED

C<static method X509_V_ERR_OCSP_VERIFY_FAILED : int ();>

Returns the value of C<X509_V_ERR_OCSP_VERIFY_FAILED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_OCSP_VERIFY_NEEDED

C<static method X509_V_ERR_OCSP_VERIFY_NEEDED : int ();>

Returns the value of C<X509_V_ERR_OCSP_VERIFY_NEEDED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_OUT_OF_MEM

C<static method X509_V_ERR_OUT_OF_MEM : int ();>

Returns the value of C<X509_V_ERR_OUT_OF_MEM>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_PATH_LENGTH_EXCEEDED

C<static method X509_V_ERR_PATH_LENGTH_EXCEEDED : int ();>

Returns the value of C<X509_V_ERR_PATH_LENGTH_EXCEEDED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_PATH_LOOP

C<static method X509_V_ERR_PATH_LOOP : int ();>

Returns the value of C<X509_V_ERR_PATH_LOOP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_PERMITTED_VIOLATION

C<static method X509_V_ERR_PERMITTED_VIOLATION : int ();>

Returns the value of C<X509_V_ERR_PERMITTED_VIOLATION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED

C<static method X509_V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED : int ();>

Returns the value of C<X509_V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED

C<static method X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED : int ();>

Returns the value of C<X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_PROXY_SUBJECT_NAME_VIOLATION

C<static method X509_V_ERR_PROXY_SUBJECT_NAME_VIOLATION : int ();>

Returns the value of C<X509_V_ERR_PROXY_SUBJECT_NAME_VIOLATION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN

C<static method X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN : int ();>

Returns the value of C<X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_STORE_LOOKUP

C<static method X509_V_ERR_STORE_LOOKUP : int ();>

Returns the value of C<X509_V_ERR_STORE_LOOKUP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_SUBJECT_ISSUER_MISMATCH

C<static method X509_V_ERR_SUBJECT_ISSUER_MISMATCH : int ();>

Returns the value of C<X509_V_ERR_SUBJECT_ISSUER_MISMATCH>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_SUBTREE_MINMAX

C<static method X509_V_ERR_SUBTREE_MINMAX : int ();>

Returns the value of C<X509_V_ERR_SUBTREE_MINMAX>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256

C<static method X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256 : int ();>

Returns the value of C<X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_SUITE_B_INVALID_ALGORITHM

C<static method X509_V_ERR_SUITE_B_INVALID_ALGORITHM : int ();>

Returns the value of C<X509_V_ERR_SUITE_B_INVALID_ALGORITHM>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_SUITE_B_INVALID_CURVE

C<static method X509_V_ERR_SUITE_B_INVALID_CURVE : int ();>

Returns the value of C<X509_V_ERR_SUITE_B_INVALID_CURVE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM

C<static method X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM : int ();>

Returns the value of C<X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_SUITE_B_INVALID_VERSION

C<static method X509_V_ERR_SUITE_B_INVALID_VERSION : int ();>

Returns the value of C<X509_V_ERR_SUITE_B_INVALID_VERSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED

C<static method X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED : int ();>

Returns the value of C<X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY

C<static method X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY : int ();>

Returns the value of C<X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE

C<static method X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE : int ();>

Returns the value of C<X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE

C<static method X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE : int ();>

Returns the value of C<X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNABLE_TO_GET_CRL

C<static method X509_V_ERR_UNABLE_TO_GET_CRL : int ();>

Returns the value of C<X509_V_ERR_UNABLE_TO_GET_CRL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER

C<static method X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER : int ();>

Returns the value of C<X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT

C<static method X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT : int ();>

Returns the value of C<X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY

C<static method X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY : int ();>

Returns the value of C<X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE

C<static method X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE : int ();>

Returns the value of C<X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION

C<static method X509_V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION : int ();>

Returns the value of C<X509_V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION

C<static method X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION : int ();>

Returns the value of C<X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNNESTED_RESOURCE

C<static method X509_V_ERR_UNNESTED_RESOURCE : int ();>

Returns the value of C<X509_V_ERR_UNNESTED_RESOURCE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNSPECIFIED

C<static method X509_V_ERR_UNSPECIFIED : int ();>

Returns the value of C<X509_V_ERR_UNSPECIFIED>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX

C<static method X509_V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX : int ();>

Returns the value of C<X509_V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNSUPPORTED_CONSTRAINT_TYPE

C<static method X509_V_ERR_UNSUPPORTED_CONSTRAINT_TYPE : int ();>

Returns the value of C<X509_V_ERR_UNSUPPORTED_CONSTRAINT_TYPE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNSUPPORTED_EXTENSION_FEATURE

C<static method X509_V_ERR_UNSUPPORTED_EXTENSION_FEATURE : int ();>

Returns the value of C<X509_V_ERR_UNSUPPORTED_EXTENSION_FEATURE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_ERR_UNSUPPORTED_NAME_SYNTAX

C<static method X509_V_ERR_UNSUPPORTED_NAME_SYNTAX : int ();>

Returns the value of C<X509_V_ERR_UNSUPPORTED_NAME_SYNTAX>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_ALLOW_PROXY_CERTS

C<static method X509_V_FLAG_ALLOW_PROXY_CERTS : int ();>

Returns the value of C<X509_V_FLAG_ALLOW_PROXY_CERTS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_CB_ISSUER_CHECK

C<static method X509_V_FLAG_CB_ISSUER_CHECK : int ();>

Returns the value of C<X509_V_FLAG_CB_ISSUER_CHECK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_CHECK_SS_SIGNATURE

C<static method X509_V_FLAG_CHECK_SS_SIGNATURE : int ();>

Returns the value of C<X509_V_FLAG_CHECK_SS_SIGNATURE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_CRL_CHECK

C<static method X509_V_FLAG_CRL_CHECK : int ();>

Returns the value of C<X509_V_FLAG_CRL_CHECK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_CRL_CHECK_ALL

C<static method X509_V_FLAG_CRL_CHECK_ALL : int ();>

Returns the value of C<X509_V_FLAG_CRL_CHECK_ALL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_EXPLICIT_POLICY

C<static method X509_V_FLAG_EXPLICIT_POLICY : int ();>

Returns the value of C<X509_V_FLAG_EXPLICIT_POLICY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_EXTENDED_CRL_SUPPORT

C<static method X509_V_FLAG_EXTENDED_CRL_SUPPORT : int ();>

Returns the value of C<X509_V_FLAG_EXTENDED_CRL_SUPPORT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_IGNORE_CRITICAL

C<static method X509_V_FLAG_IGNORE_CRITICAL : int ();>

Returns the value of C<X509_V_FLAG_IGNORE_CRITICAL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_INHIBIT_ANY

C<static method X509_V_FLAG_INHIBIT_ANY : int ();>

Returns the value of C<X509_V_FLAG_INHIBIT_ANY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_INHIBIT_MAP

C<static method X509_V_FLAG_INHIBIT_MAP : int ();>

Returns the value of C<X509_V_FLAG_INHIBIT_MAP>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_LEGACY_VERIFY

C<static method X509_V_FLAG_LEGACY_VERIFY : int ();>

Returns the value of C<X509_V_FLAG_LEGACY_VERIFY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_NOTIFY_POLICY

C<static method X509_V_FLAG_NOTIFY_POLICY : int ();>

Returns the value of C<X509_V_FLAG_NOTIFY_POLICY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_NO_ALT_CHAINS

C<static method X509_V_FLAG_NO_ALT_CHAINS : int ();>

Returns the value of C<X509_V_FLAG_NO_ALT_CHAINS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_NO_CHECK_TIME

C<static method X509_V_FLAG_NO_CHECK_TIME : int ();>

Returns the value of C<X509_V_FLAG_NO_CHECK_TIME>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_PARTIAL_CHAIN

C<static method X509_V_FLAG_PARTIAL_CHAIN : int ();>

Returns the value of C<X509_V_FLAG_PARTIAL_CHAIN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_POLICY_CHECK

C<static method X509_V_FLAG_POLICY_CHECK : int ();>

Returns the value of C<X509_V_FLAG_POLICY_CHECK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_POLICY_MASK

C<static method X509_V_FLAG_POLICY_MASK : int ();>

Returns the value of C<X509_V_FLAG_POLICY_MASK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_SUITEB_128_LOS

C<static method X509_V_FLAG_SUITEB_128_LOS : int ();>

Returns the value of C<X509_V_FLAG_SUITEB_128_LOS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_SUITEB_128_LOS_ONLY

C<static method X509_V_FLAG_SUITEB_128_LOS_ONLY : int ();>

Returns the value of C<X509_V_FLAG_SUITEB_128_LOS_ONLY>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_SUITEB_192_LOS

C<static method X509_V_FLAG_SUITEB_192_LOS : int ();>

Returns the value of C<X509_V_FLAG_SUITEB_192_LOS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_TRUSTED_FIRST

C<static method X509_V_FLAG_TRUSTED_FIRST : int ();>

Returns the value of C<X509_V_FLAG_TRUSTED_FIRST>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_USE_CHECK_TIME

C<static method X509_V_FLAG_USE_CHECK_TIME : int ();>

Returns the value of C<X509_V_FLAG_USE_CHECK_TIME>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_USE_DELTAS

C<static method X509_V_FLAG_USE_DELTAS : int ();>

Returns the value of C<X509_V_FLAG_USE_DELTAS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_FLAG_X509_STRICT

C<static method X509_V_FLAG_X509_STRICT : int ();>

Returns the value of C<X509_V_FLAG_X509_STRICT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X509_V_OK

C<static method X509_V_OK : int ();>

Returns the value of C<X509_V_OK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_COMPAT

C<static method XN_FLAG_COMPAT : int ();>

Returns the value of C<XN_FLAG_COMPAT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_DN_REV

C<static method XN_FLAG_DN_REV : int ();>

Returns the value of C<XN_FLAG_DN_REV>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_DUMP_UNKNOWN_FIELDS

C<static method XN_FLAG_DUMP_UNKNOWN_FIELDS : int ();>

Returns the value of C<XN_FLAG_DUMP_UNKNOWN_FIELDS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_FN_ALIGN

C<static method XN_FLAG_FN_ALIGN : int ();>

Returns the value of C<XN_FLAG_FN_ALIGN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_FN_LN

C<static method XN_FLAG_FN_LN : int ();>

Returns the value of C<XN_FLAG_FN_LN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_FN_MASK

C<static method XN_FLAG_FN_MASK : int ();>

Returns the value of C<XN_FLAG_FN_MASK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_FN_NONE

C<static method XN_FLAG_FN_NONE : int ();>

Returns the value of C<XN_FLAG_FN_NONE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_FN_OID

C<static method XN_FLAG_FN_OID : int ();>

Returns the value of C<XN_FLAG_FN_OID>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_FN_SN

C<static method XN_FLAG_FN_SN : int ();>

Returns the value of C<XN_FLAG_FN_SN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_MULTILINE

C<static method XN_FLAG_MULTILINE : int ();>

Returns the value of C<XN_FLAG_MULTILINE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_ONELINE

C<static method XN_FLAG_ONELINE : int ();>

Returns the value of C<XN_FLAG_ONELINE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_RFC2253

C<static method XN_FLAG_RFC2253 : int ();>

Returns the value of C<XN_FLAG_RFC2253>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_SEP_COMMA_PLUS

C<static method XN_FLAG_SEP_COMMA_PLUS : int ();>

Returns the value of C<XN_FLAG_SEP_COMMA_PLUS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_SEP_CPLUS_SPC

C<static method XN_FLAG_SEP_CPLUS_SPC : int ();>

Returns the value of C<XN_FLAG_SEP_CPLUS_SPC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_SEP_MASK

C<static method XN_FLAG_SEP_MASK : int ();>

Returns the value of C<XN_FLAG_SEP_MASK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_SEP_MULTILINE

C<static method XN_FLAG_SEP_MULTILINE : int ();>

Returns the value of C<XN_FLAG_SEP_MULTILINE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_SEP_SPLUS_SPC

C<static method XN_FLAG_SEP_SPLUS_SPC : int ();>

Returns the value of C<XN_FLAG_SEP_SPLUS_SPC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 XN_FLAG_SPC_EQ

C<static method XN_FLAG_SPC_EQ : int ();>

Returns the value of C<XN_FLAG_SPC_EQ>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_NO_LOAD_SSL_STRINGS

C<static method OPENSSL_INIT_NO_LOAD_SSL_STRINGS : int ();>

Returns the value of C<OPENSSL_INIT_NO_LOAD_SSL_STRINGS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_LOAD_SSL_STRINGS

C<static method OPENSSL_INIT_LOAD_SSL_STRINGS : int ();>

Returns the value of C<OPENSSL_INIT_LOAD_SSL_STRINGS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_NO_LOAD_CRYPTO_STRINGS

C<static method OPENSSL_INIT_NO_LOAD_CRYPTO_STRINGS : int ();>

Returns the value of C<OPENSSL_INIT_NO_LOAD_CRYPTO_STRINGS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_LOAD_CRYPTO_STRINGS

C<static method OPENSSL_INIT_LOAD_CRYPTO_STRINGS : int ();>

Returns the value of C<OPENSSL_INIT_LOAD_CRYPTO_STRINGS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ADD_ALL_CIPHERS

C<static method OPENSSL_INIT_ADD_ALL_CIPHERS : int ();>

Returns the value of C<OPENSSL_INIT_ADD_ALL_CIPHERS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ADD_ALL_DIGESTS

C<static method OPENSSL_INIT_ADD_ALL_DIGESTS : int ();>

Returns the value of C<OPENSSL_INIT_ADD_ALL_DIGESTS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_NO_ADD_ALL_CIPHERS

C<static method OPENSSL_INIT_NO_ADD_ALL_CIPHERS : int ();>

Returns the value of C<OPENSSL_INIT_NO_ADD_ALL_CIPHERS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_NO_ADD_ALL_DIGESTS

C<static method OPENSSL_INIT_NO_ADD_ALL_DIGESTS : int ();>

Returns the value of C<OPENSSL_INIT_NO_ADD_ALL_DIGESTS>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_LOAD_CONFIG

C<static method OPENSSL_INIT_LOAD_CONFIG : int ();>

Returns the value of C<OPENSSL_INIT_LOAD_CONFIG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_NO_LOAD_CONFIG

C<static method OPENSSL_INIT_NO_LOAD_CONFIG : int ();>

Returns the value of C<OPENSSL_INIT_NO_LOAD_CONFIG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ASYNC

C<static method OPENSSL_INIT_ASYNC : int ();>

Returns the value of C<OPENSSL_INIT_ASYNC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ENGINE_RDRAND

C<static method OPENSSL_INIT_ENGINE_RDRAND : int ();>

Returns the value of C<OPENSSL_INIT_ENGINE_RDRAND>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ENGINE_DYNAMIC

C<static method OPENSSL_INIT_ENGINE_DYNAMIC : int ();>

Returns the value of C<OPENSSL_INIT_ENGINE_DYNAMIC>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ENGINE_OPENSSL

C<static method OPENSSL_INIT_ENGINE_OPENSSL : int ();>

Returns the value of C<OPENSSL_INIT_ENGINE_OPENSSL>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ENGINE_CRYPTODEV

C<static method OPENSSL_INIT_ENGINE_CRYPTODEV : int ();>

Returns the value of C<OPENSSL_INIT_ENGINE_CRYPTODEV>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ENGINE_CAPI

C<static method OPENSSL_INIT_ENGINE_CAPI : int ();>

Returns the value of C<OPENSSL_INIT_ENGINE_CAPI>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ENGINE_PADLOCK

C<static method OPENSSL_INIT_ENGINE_PADLOCK : int ();>

Returns the value of C<OPENSSL_INIT_ENGINE_PADLOCK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ENGINE_AFALG

C<static method OPENSSL_INIT_ENGINE_AFALG : int ();>

Returns the value of C<OPENSSL_INIT_ENGINE_AFALG>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ENGINE_ALL_BUILTIN

C<static method OPENSSL_INIT_ENGINE_ALL_BUILTIN : int ();>

Returns the value of C<OPENSSL_INIT_ENGINE_ALL_BUILTIN>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_ATFORK

C<static method OPENSSL_INIT_ATFORK : int ();>

Returns the value of C<OPENSSL_INIT_ATFORK>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 OPENSSL_INIT_NO_ATEXIT

C<static method OPENSSL_INIT_NO_ATEXIT : int ();>

Returns the value of C<OPENSSL_INIT_NO_ATEXIT>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TLSEXT_NAMETYPE_host_name

C<static method TLSEXT_NAMETYPE_host_name : int ();>

Returns the value of C<TLSEXT_NAMETYPE_host_name>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EVP_MAX_MD_SIZE

C<static method EVP_MAX_MD_SIZE : int ();>

Returns the value of C<EVP_MAX_MD_SIZE>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SSL_MODE_SEND_FALLBACK_SCSV

C<static method SSL_MODE_SEND_FALLBACK_SCSV : int ();>

Returns the value of C<SSL_MODE_SEND_FALLBACK_SCSV>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

