package SPVM::Net::SSLeay::X509_STORE_CTX;



1;

=head1 Name

SPVM::Net::SSLeay::X509_STORE_CTX - X509_STORE_CTX Data Structure in OpenSSL

=head1 Description

Net::SSLeay::X509_STORE_CTX class in L<SPVM> represents L<X509_STORE_CTX|https://docs.openssl.org/3.1/man3/X509_STORE_CTX_new/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::X509_STORE_CTX;

=head1 Class Methods

C<method get1_issuer : int ($issuer_ref : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>, $ctx : L<Net::SSLeay::X509_STORE_CTX|SPVM::Net::SSLeay::X509_STORE_CTX>, $x : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<X509_STORE_CTX_get1_issuer|https://docs.openssl.org/master/man3/OCSP_response_status> function given $issuer_ref, $ctx, $x.
, sets $issuer_ref at index 0 to the new object, and returns the return value of the native function.

Exceptions:

The output array of the Net::SSLeay::X509 $issuer_ref must be defined. Otherwise an exception is thrown.

The length of $issuer_ref must be 1. Otherwise an exception is thrown.

The Net::SSLeay::X509_STORE_CTX object $ctx must be defined. Otherwise an exception is thrown.

The X509 object $x must be defined. Otherwise an exception is thrown.

If X509_STORE_CTX_get1_issuer failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 set_error

C<method set_error : void ($s : int);>

Calls native L<X509_STORE_CTX_set_error|https://docs.openssl.org/master/man3/X509_STORE_CTX_get_error> function given the pointer value of the instance, $s.

=head2 get_error

C<method get_error : int ();>

Calls native L<X509_STORE_CTX_get_error|https://docs.openssl.org/master/man3/X509_STORE_CTX_get_error> function, and returns its return value.

=head2 get_error_depth

C<method get_error_depth : int ();>

Calls native L<X509_STORE_CTX_get_error_depth|https://docs.openssl.org/master/man3/X509_STORE_CTX_get_error_depth> function, and returns its return value.

=head2 get_current_cert

C<method get_current_cert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls native L<X509_STORE_CTX_get_current_cert|https://docs.openssl.org/master/man3/X509_STORE_CTX_get_error_depth> function.

If the return value is NULL, returns undef.

Otherwise, creates a new new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the new object to the return value of the native function, sets C<no_free> flag of the new object to 1, returns the new object.

=head2 Init

C<method Init : int ($trust_store : L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>, $target : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>, $untrusted_array : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>[]);>

Calls native L<X509_STORE_CTX_init|https://docs.openssl.org/3.2/man3/X509_STORE_CTX_new> function given the pointer value of $trust_store, the pointer value of $target, the value that converts $untrusted_array to STACK_OF(X509) type, and returns its return value.

Exceptions:

The X509 object $target must be defined. Otherwise an exception is thrown.

The X509 array $untrusted_array must be defined. Otherwise an exception is thrown.

If X509_STORE_CTX_init failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
