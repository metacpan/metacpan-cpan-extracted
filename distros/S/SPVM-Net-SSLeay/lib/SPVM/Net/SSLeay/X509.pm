package SPVM::Net::SSLeay::X509;



1;

=head1 Name

SPVM::Net::SSLeay::X509 - X509 data structure in OpenSSL

=head1 Description

Net::SSLeay::X509 class in L<SPVM> represents L<X509|https://docs.openssl.org/3.1/man3/X509_new/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::X509;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls native L<X509_new|https://docs.openssl.org/1.0.2/man3/X509_new/> function, creates a new  L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If X509_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 check_issued

C<static method check_issued : int ($issuer : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>, $subject : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<X509_check_issued|https://docs.openssl.org/1.1.1/man3/X509_check_issued> function given the pointer value of $issuer, the pointer value of $subject, and returns its return value.

Exceptions:

The X509 object $issuer must be defined. Otherwise an exception is thrown.

The X509 object $subject must be defined. Otherwise an exception is thrown.

=head1 Instance Methods

=head2 get_serialNumber

C<method get_serialNumber : L<Net::SSLeay::ASN1_INTEGER|SPVM::Net::SSLeay::ASN1_INTEGER> ()>

Calls native L<X509_get_serialNumber|https://docs.openssl.org/3.2/man3/X509_get_serialNumber/> function given the pointer value of the instance, copies its return value using native L<ASN1_INTEGER_dup|https://docs.openssl.org/master/man3/X509_dup/> function, creates a new L<Net::SSLeay::ASN1_INTEGER|SPVM::Net::SSLeay::X509_NAME> object, sets the pointer value of the new object to the native copied value, and returns the new object.

=head2 get_issuer_name

C<method get_issuer_name : L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> ();>

Calls native L<X509_get_issuer_name|https://docs.openssl.org/3.3/man3/X509_get_subject_name> function given the pointer value of the instance, copies its return value using native L<X509_NAME_dup|https://docs.openssl.org/master/man3/X509_dup/> function, creates a new L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> object, sets the pointer value of the new object to the native copied value, and returns the new object.

=head2 get_subject_name

C<method get_subject_name : L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> ();>

Calls native L<X509_get_subject_name|https://docs.openssl.org/3.3/man3/X509_get_subject_name> function given the pointer value of the instance, copies its return value using native L<X509_NAME_dup|https://docs.openssl.org/master/man3/X509_dup/> function, creates a new L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> object, sets the pointer value of the new object to the native copied value, and returns the new object.

=head2 get_pubkey

C<method get_pubkey : L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY> ();>

Calls native L<X509_get_pubkey|https://docs.openssl.org/master/man3/X509_get_pubkey> function, creates a new L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY> object, sets the pointer value of the new object to the return vlaue of the native function, and returns the new object.

Exceptions:

If X509_get_ext failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

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

Calls native L<X509_get_ext|https://docs.openssl.org/1.1.1/man3/X509v3_get_ext_by_NID> function given the pointer value of the instance, $loc, copies its return value using native L<X509_EXTENSION_dup|https://docs.openssl.org/3.0/man3/X509_dup/> function, creates a new L<Net::SSLeay::X509_EXTENSION|SPVM::Net::SSLeay::X509_EXTENSION> object, sets the pointer value of the new object to the native copied value, and returns the new object.

Exceptions:

If X509_get_ext failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 get_subjectAltNames

C<method get_subjectAltNames : L<Net::SSLeay::GENERAL_NAME|SPVM::Net::SSLeay::GENERAL_NAME>[] ();>

Gets C<STACK_OF(GENERAL_NAME)> data by the following native C codes. C<self> is the pointer value of the instancce.

  int32_t ext_loc = X509_get_ext_by_NID(self, NID_subject_alt_name, -1);
  STACK_OF(GENERAL_NAME)* sans_stack = NULL;
  if (ext_loc >= 0) {
    X509_EXTENSION* ext = X509_get_ext(self, ext_loc);
    assert(ext);
    sans_stack = STACK_OF(GENERAL_NAME) *)X509V3_EXT_d2i(ext);
  }

And creates a new L<Net::SSLeay::GENERAL_NAME|SPVM::Net::SSLeay::GENERAL_NAME> array,

And runs the following loop: copies the element at index $i of the return value(C<STACK_OF(GENERAL_NAME)>) of the native function using native L<GENERAL_NAME_dup|https://docs.openssl.org/1.1.1/man3/X509_dup/>, creates a new L<Net::SSLeay::GENERAL_NAME|SPVM::Net::SSLeay::GENERAL_NAME> object, sets the pointer value of the new object to the native copied value, and puses the new object to the new array.

And returns the new array.

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

=head2 dup

C<method dup : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls native L<X509_dup|https://docs.openssl.org/3.3/man3/X509_dup> function given the pointer value of the instance, creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

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

