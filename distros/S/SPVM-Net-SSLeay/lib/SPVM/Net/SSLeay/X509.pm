package SPVM::Net::SSLeay::X509;



1;

=head1 Name

SPVM::Net::SSLeay::X509 - X509 data structure in OpenSSL

=head1 Description

Net::SSLeay::X509 class in L<SPVM> represents L<X509|https://docs.openssl.org/3.1/man3/X509_new/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::X509;

=head1 Instance Methods

=head2 get_issuer_name

C<method get_issuer_name : L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> ();>

Calls native L<X509_get_issuer_name|https://docs.openssl.org/3.3/man3/X509_get_subject_name> function, creates a new L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> object, sets the pointer value of the new object to the return vlaue of the native function, and returns the new object.

The C<no_free> flag of the new object is set to 1.

=head2 get_subject_name

C<method get_subject_name : L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> ();>

Calls native L<X509_get_subject_name|https://docs.openssl.org/3.3/man3/X509_get_subject_name> function, creates a new L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> object, sets the pointer value of the new object to the return vlaue of the native function, and returns the new object.

The C<no_free> flag of the new object is set to 1.

=head2 digest

C<method digest : int ($type : L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD>, $md : mutable string, $len_ref : int*);>

Calls native L<X509_digest|https://docs.openssl.org/master/man3/X509_digest> function given the pointer value of the instance, $type, the pointer value of $md, $len_ref, and returns its return value.

Exceptions:

The digest type $type must be defined. Otherwise an exception is thrown.

The output buffer $md must be defined. Otherwise an exception is thrown.

The length of output buffer $md must be greater than or equal to EVP_MAX_MD_SIZE. Otherwise an exception is thrown.

If X509_digest failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 digest_return_string

C<method digest_return_string : string ($type : Net::SSLeay::EVP_MD);>

Calls L</"digest"> method given appropriate arguments, and returns the output string.

=head2 pubkey_digest

C<method pubkey_digest : int ($type : L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD>, $md : mutable string, $len_ref : int*);>

Calls native L<X509_pubkey_digest|https://docs.openssl.org/master/man3/X509_pubkey_digest> function given the pointer value of the instance, $type, the pointer value of $md, $len_ref, and returns its return value.

Exceptions:

The digest type $type must be defined. Otherwise an exception is thrown.

The output buffer $md must be defined. Otherwise an exception is thrown.

The length of output buffer $md must be greater than or equal to EVP_MAX_MD_SIZE. Otherwise an exception is thrown.

If X509_pubkey_digest failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 pubkey_digest_return_string

C<method pubkey_digest_return_string : string ($type : Net::SSLeay::EVP_MD);>

Calls L</"pubkey_digest"> method given appropriate arguments, and returns the output string.

=head2 dup

C<method dup : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls native L<X509_dup|https://docs.openssl.org/3.3/man3/X509_dup> function given the pointer value of the instance, creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

=head2 check_issued

C<method check_issued : int ($subject : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<X509_check_issued|https://docs.openssl.org/1.1.1/man3/X509_check_issued> function given the pointer value of the instance, the pointer value of $subject, and returns its return value.

Exceptions:

The X509 object $subject must be defined. Otherwise an exception is thrown.

=head2 get_ocsp_uri

C<method get_ocsp_uri : string ();>

Returns OCSP URI in the certificate $cert.

If not found, returns undef.

=head2 get_ext_by_NID

C<method get_ext_by_NID : int ($nid : int, $lastpos : int);>

Calls native L<X509_get_ext_by_NID|https://docs.openssl.org/1.1.1/man3/X509v3_get_ext_by_NID> function given the pointer value of the instance, $nid, $lastpos, and returns its return value.

Exceptions:

If X509_get_ext_by_NID failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 get_ext_count

C<method get_ext_count : int ();>

Calls native L<X509_get_ext_count|https://docs.openssl.org/1.1.1/man3/X509v3_get_ext_by_NID> function given the pointer value of the instance, and returns its return value.

=head2 get_ext

C<method get_ext : L<Net::SSLeay::X509_EXTENSION|SPVM::Net::SSLeay::X509_EXTENSION> ($loc : int);>

Calls native L<X509_get_ext|https://docs.openssl.org/1.1.1/man3/X509v3_get_ext_by_NID> function given the pointer value of the instance, $loc, creates a new L<Net::SSLeay::X509_EXTENSION|SPVM::Net::SSLeay::X509_EXTENSION> object, sets the pointer value of the new object to the return value of the native function, sets C<no_free> flag of the new object to 1, creates a reference from the new object to the instance, and returns the new object.

Exceptions:

If X509_get_ext failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<X509_free|https://docs.openssl.org/3.1/man3/X509_free/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 FAQ

=head2 How to create a new Net::SSLeay::X509 object?

A way is reading PEM file by calling native L<Net::SSLeay::PEM#read_bio_X509|SPVM::Net::SSLeay::PEM/"read_bio_X509"> method.

=head1 See Also

=over 2

=item * L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>

=item * L<Net::SSLeay::PEM|SPVM::Net::SSLeay::PEM>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

