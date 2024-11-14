package SPVM::Net::SSLeay::OCSP;



1;

=head1 Name

SPVM::Net::SSLeay::OCSP - OCSP Name Space in OpenSSL

=head1 Description

Net::SSLeay::OCSP class in L<SPVM> represents L<OCSP|https://docs.openssl.org/master/man3/OCSP_response_status/> Name Space in OpenSSL

=head1 Usage

  use Net::SSLeay::OCSP;

=head1 Class Methods

=head2 response_status_str

C<static method response_status_str : string ($code : long);>

Calls native L<OCSP_response_status_str|https://man.openbsd.org/OCSP_basic_sign.3> function given $code, and returns its return value.

=head2 response_status

C<static method response_status : int ($resp : L<Net::SSLeay::OCSP_RESPONSE|SPVM::Net::SSLeay::OCSP_RESPONSE>);>

Calls native L<OCSP_response_status|https://docs.openssl.org/1.1.1/man3/OCSP_response_status> function given $resp, and returns its return value.

Exceptions:

The OCSP response $resp must be defined. Otherwise an exception is thrown.

Exceptions:

If SSL_CTX_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 basic_verify

C<static method basic_verify : int ($bs : L<Net::SSLeay::OCSP_BASICRESP|SPVM::Net::SSLeay::OCSP_BASICRESP>, $certs : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>[], $st : L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>, $flags : long);>

Calls native L<OCSP_basic_verify|https://docs.openssl.org/1.1.1/man3/OCSP_resp_find_status> function, and returns its return value.

Exceptions:

If OCSP_basic_verify failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 basic_add1_cert

C<static basic_add1_cert : int ($resp : L<Net::SSLeay::OCSP_BASICRESP|SPVM::Net::SSLeay::OCSP_BASICRESP>, $cert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<OCSP_basic_add1_cert|https://github.com/openssl/openssl/blob/master/crypto/ocsp/ocsp_srv.c> function given $resp, $cert, puses $cert to the end of L<certs_list|SPVM::Net::SSLeay::OCSP_BASICRESP/"certs_list"> field of $resp, and returns its return value.

Exceptions:

The OCSP_BASICRESP object $resp must be defined. Otherwise an exception is thrown.

The X509 object $cert must be defined. Otherwise an exception is thrown.

If OCSP_basic_add1_cert failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 check_nonce

C<static method check_nonce : int ($req : L<Net::SSLeay::OCSP_REQUEST|SPVM::Net::SSLeay::OCSP_REQUEST>, $resp : L<Net::SSLeay::OCSP_BASICRESP|SPVM::Net::SSLeay::OCSP_BASICRESP>);>

Calls native L<OCSP_check_nonce|https://docs.openssl.org/1.1.1/man3/OCSP_request_add1_nonce> function given $req, $resp, and returns its return value.

Exceptions:

The OCSP_REQUEST object $req must be defined. Otherwise an exception is thrown.

The OCSP_BASICRESP $resp must be defined. Otherwise an exception is thrown.

=head2 check_validity

C<static method check_validity : int ($thisupd : L<Net::SSLeay::ASN1_GENERALIZEDTIME|SPVM::Net::SSLeay::ASN1_GENERALIZEDTIME>, $nextupd : L<Net::SSLeay::ASN1_GENERALIZEDTIME|SPVM::Net::SSLeay::ASN1_GENERALIZEDTIME>, $sec : long, $maxsec : long);>

Calls native L<OCSP_check_nonce|https://docs.openssl.org/1.1.1/man3/OCSP_request_add1_nonce> function given $req, $resp, and returns its return value.

Exceptions:

The ASN1_GENERALIZEDTIME object $thisupd must be defined. Otherwise an exception is thrown.

The ASN1_GENERALIZEDTIME $nextupd must be defined. Otherwise an exception is thrown.

If OCSP_check_validity failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 resp_count

C<static method resp_count : int ($bs : L<Net::SSLeay::OCSP_BASICRESP|SPVM::Net::SSLeay::OCSP_BASICRESP>);>

Calls native L<OCSP_resp_count|https://docs.openssl.org/master/man3/OCSP_resp_find_status> function given $bs, and returns its return value.

Exceptions:

The OCSP_BASICRESP object $bs must be defined. Otherwise an exception is thrown.

=head1 See Also

=over 2

=item * L<Net::SSLeay::OCSP_RESPONSE|SPVM::Net::SSLeay::OCSP_RESPONSE>

=item * L<Net::SSLeay::OCSP_REQUEST|SPVM::Net::SSLeay::OCSP_REQUEST>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

