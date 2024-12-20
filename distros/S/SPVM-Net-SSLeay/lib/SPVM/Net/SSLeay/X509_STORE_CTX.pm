package SPVM::Net::SSLeay::X509_STORE_CTX;



1;

=head1 Name

SPVM::Net::SSLeay::X509_STORE_CTX - X509_STORE_CTX Data Structure in OpenSSL

=head1 Description

Net::SSLeay::X509_STORE_CTX class in L<SPVM> represents C<X509_STORE_CTX> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::X509_STORE_CTX;

=head1 Class Methods

=head2 get1_issuer

C<static method get1_issuer : int ($issuer_ref : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>[], $ctx : L<Net::SSLeay::X509_STORE_CTX|SPVM::Net::SSLeay::X509_STORE_CTX>, $x : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<X509_STORE_CTX_get1_issuer|https://docs.openssl.org/master/man3/X509_STORE_CTX_get1_issuer> function given $issuer_ref, $ctx, $x.

And if its return value is 1, creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the new object to the value of the native output argument C<*issuer>, and sets C<$issuer_ref-E<gt>[0]> to the new object.

And returns the return value of the native function.

Exceptions:

The output array of the Net::SSLeay::X509 $issuer_ref must be 1-length array. Otherwise an exception is thrown.

The Net::SSLeay::X509_STORE_CTX object $ctx must be defined. Otherwise an exception is thrown.

The X509 object $x must be defined. Otherwise an exception is thrown.

If X509_STORE_CTX_get1_issuer failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 set_error

C<method set_error : void ($s : int);>

Calls native L<X509_STORE_CTX_set_error|https://docs.openssl.org/master/man3/X509_STORE_CTX_set_error> function given the pointer value of the instance, $s.

=head2 get_error

C<method get_error : int ();>

Calls native L<X509_STORE_CTX_get_error|https://docs.openssl.org/master/man3/X509_STORE_CTX_get_error> function given the pointer value of the instance, and returns its return value.

=head2 get_error_depth

C<method get_error_depth : int ();>

Calls native L<X509_STORE_CTX_get_error_depth|https://docs.openssl.org/master/man3/X509_STORE_CTX_get_error_depth> function given the pointer value of the instance, and returns its return value.

=head2 get_current_cert

C<method get_current_cert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls native L<X509_STORE_CTX_get_current_cert|https://docs.openssl.org/master/man3/X509_STORE_CTX_get_current_cert> function given the pointer value of the instance.

If its return value is NULL, returns undef.

Otherwise, increments the refernece count of its return value using native L<X509_up_ref|https://docs.openssl.org/master/man3/X509_up_ref> function, creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

=head1 See Also

=over 2

=item * L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>

=item * L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
