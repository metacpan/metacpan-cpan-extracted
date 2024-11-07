package SPVM::Net::SSLeay::SSL_CTX;



1;

=head1 Name

SPVM::Net::SSLeay::SSL_CTX - SSL_CTX data structure in OpenSSL

=head1 Description

Net::SSLeay::SSL_CTX class in L<SPVM> represents SSL_CTX data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::SSL_CTX;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> ($method : L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD>);>

Creates a new L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> given the L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD> object $method, and returns the new object.

C<SSL_MODE_AUTO_RETRY> mode is enabled.

=head1 Instance Methods

=head2 set_mode

C<method set_mode : long ($mode : long);>

Adds the mode $mode by calling L<SSL_CTX_set_mode|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_mode> function, and returns the updated mode.

=head2 set_verify

C<method set_verify : void ($mode : int);>

Sets the verification flags $mode by calling L<SSL_CTX_set_verify|https://docs.openssl.org/master/man3/SSL_CTX_set_verify/> function.

=head2 get0_param

C<method get0_param : L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM> ();>

Creates a L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM> object, calls L<SSL_CTX_get0_param|https://docs.openssl.org/master/man3/SSL_CTX_get0_param/> function, sets the pointer value of the new object to the return value of the function, and returns the new object.

=head2 load_verify_locations

C<method load_verify_locations : int ($path : string);>

Specifies the locations, at which CA certificates for verification purposes are located by calling L<SSL_CTX_load_verify_locations|https://docs.openssl.org/master/man3/SSL_CTX_load_verify_locations/> function.

Exceptions:

If SSL_CTX_load_verify_locations failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_default_verify_paths

C<method set_default_verify_paths : int ();>

Specifies that the default locations from which CA certificates are loaded should be used by calling L<set_default_verify_paths|https://docs.openssl.org/master/man3/SSL_CTX_load_verify_locations/> function.

Exceptions:

If SSL_CTX_set_default_verify_paths failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_certificate_file

C<method use_certificate_file : int ($file : string, $type : int);>

Loads the first certificate stored in the file $file and the type $type by calling L<use_certificate_file|https://docs.openssl.org/master/man3/SSL_CTX_use_certificate/> function.

Exceptions:

The file $file must be defined. Otherwise an exception is thrown.

If SSL_CTX_use_certificate_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_certificate_chain_file

C<method use_certificate_chain_file : int ($file : string);>

Loads a certificate chain from the file $file by calling L<use_certificate_chain_file|https://docs.openssl.org/1.1.1/man3/SSL_CTX_use_certificate/> function.
 
Exceptions:

If SSL_CTX_use_certificate_chain_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_PrivateKey_file

C<method use_PrivateKey_file : int ($file : string, $type : int);>

Adds the first private key found in the file $file and the type $type by calling L<use_PrivateKey_file|https://docs.openssl.org/3.1/man3/SSL_CTX_use_certificate/> function.

Exceptions:

The file $file must be defined. Otherwise an exception is thrown.

If SSL_CTX_use_PrivateKey_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_cipher_list

C<method set_cipher_list : int ($str : string);>

Sets the list of available ciphers by calling L<set_cipher_list|https://docs.openssl.org/master/man3/SSL_CTX_set_cipher_list/> function.

Exceptions:

The cipher list $str must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_cipher_list failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_ciphersuites

C<method set_ciphersuites : int ($str : string);>

Configures the available TLSv1.3 ciphersuites by calling L<set_ciphersuites|https://docs.openssl.org/master/man3/SSL_CTX_set_cipher_list/> function.

Exceptions:

The ciphersuites $str must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_ciphersuites failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 get_cert_store

C<method get_cert_store : L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE> ();>

Creates a new L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>, calls L<SSL_CTX_set_cert_store|https://docs.openssl.org/master/man3/SSL_CTX_set_cert_store/> function, sets the pointer value of the new object to the return value of the function, and returns the new object.

=head2 set_options

C<method set_options : long ($options : long);>

Adds the options set via bitmask in the options $options by calling L<set_options|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_options> function, and returns its return value.

=head2 get_options

C<method get_options : long ();>

Returns the options by calling L<SSL_CTX_get_options|https://docs.openssl.org/3.1/man3/SSL_CTX_set_options/> function.

=head2 clear_options

C<method clear_options : long ($options : long);>

Clears the options set via bit-mask in the options $options by calling L<SSL_CTX_clear_options|https://docs.openssl.org/3.1/man3/SSL_CTX_set_options/> function, and returns its return value.

=head2 DESTROY

C<method DESTROY : void ();>

Frees L<SSL_CTX|https://docs.openssl.org/3.1/man3/SSL_CTX_new/> object by calling L<SSL_CTX_free|https://docs.openssl.org/3.1/man3/SSL_CTX_free/> function if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD>

=item * L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM>

=item * L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

