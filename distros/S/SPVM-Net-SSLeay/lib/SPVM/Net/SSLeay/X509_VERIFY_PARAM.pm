package SPVM::Net::SSLeay::X509_VERIFY_PARAM;



1;

=head1 Name

SPVM::Net::SSLeay::X509_VERIFY_PARAM - X509_VERIFY_PARAM Data Structure in OpenSSL.

=head1 Description

Net::SSLeay::X509_VERIFY_PARAM class in L<SPVM> represents L<X509_VERIFY_PARAM|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::X509_VERIFY_PARAM;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM> ();>

Calls native L<X509_VERIFY_PARAM_new|https://man.openbsd.org/X509_VERIFY_PARAM_inherit.3> function, creates a new  L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If X509_VERIFY_PARAM_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 get_flags

C<method get_flags : long ();>

Calls native L<X509_VERIFY_PARAM_get_flags|https://docs.openssl.org/master/man3/X509_VERIFY_PARAM_clear_flags> function given the pointer value of the instance, and returns its return value.

=head2 set_flags

C<method set_flags : void ($flags : long);>

Calls native L<X509_VERIFY_PARAM_set_flags|https://docs.openssl.org/master/man3/X509_VERIFY_PARAM_set_flags> function given the pointer value of the instance, $flags, and returns its return value.

Exceptions:

If X509_VERIFY_PARAM_set_flags failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 clear_flags

C<method clear_flags : void ($flags : long);>

Calls native L<X509_VERIFY_PARAM_clear_flags|https://docs.openssl.org/master/man3/X509_VERIFY_PARAM_clear_flags> function given the pointer value of the instance, $flags, and returns its return value.

Exceptions:

If X509_VERIFY_PARAM_clear_flags failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 get_hostflags

C<method get_hostflags : int ();>

Calls native L<X509_VERIFY_PARAM_get_hostflags|https://docs.openssl.org/master/man3/X509_VERIFY_PARAM_clear_flags> function given the pointer value of the instance, and returns its return value.

=head2 set_hostflags

C<method set_hostflags : void ($flags : int);>

Calls native L<X509_VERIFY_PARAM_set_hostflags|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> function given the pointer value of the instance, $flags.

=head2 set1_host

C<method set1_host : int ($name : string, $namelen : int = -1);>

Calls native L<X509_VERIFY_PARAM_set1_host|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> function given the pointer value of the instance, $name, $namelen, and returns its return value.

If $namelen is less than 0, it is set to the length of $name.

Exceptions:

The host name $name must be defined. Otherwise an exception is thrown.

The length $namelen must be greater than or equal to the length of the host name $name. Otherwise an exception is thrown.

If X509_VERIFY_PARAM_set1_host failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set1_ip_asc

C<method set1_ip_asc : int ($ipasc : string);>

Calls native L<X509_VERIFY_PARAM_set1_ip_asc|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> function given the pointer value of the instance, $ipasc, and returns its return value.

Exceptions:

The IP address $ipasc must be defined. Otherwise an exception is thrown.

If X509_VERIFY_PARAM_set1_email failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set1_email

C<method set1_email : int ($email : string, $emaillen : int = -1);>

Calls native L<X509_VERIFY_PARAM_set1_email|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> function given the pointer value of the instance, $email, $emaillen, and returns its return value.

If $namelen is less than 0, it is set to the length of $name.

Exceptions:

The email $email must be defined. Otherwise an exception is thrown.

The length $emaillen must be greater than or equal to the length of the host name $name. Otherwise an exception is thrown.

If X509_VERIFY_PARAM_set1_email failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<X509_VERIFY_PARAM_free|https://docs.openssl.org/1.0.2/man3/X509_VERIFY_PARAM_set_flags/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 FAQ

=head2 How to get a Net::SSLeay::X509_VERIFY_PARAM object?

A way is using L<Net::SSLeay::SSL_CTX#get0_param|SPVM::Net::SSLeay::SSL_CTX/"get0_param"> method.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

