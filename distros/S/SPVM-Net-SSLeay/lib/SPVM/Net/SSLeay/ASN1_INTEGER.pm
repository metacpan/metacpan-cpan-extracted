package SPVM::Net::SSLeay::ASN1_INTEGER;



1;

=head1 Name

SPVM::Net::SSLeay::ASN1_INTEGER - ASN1_INTEGER Data Structure in OpenSSL

=head1 Description

Net::SSLeay::ASN1_INTEGER class in L<SPVM> represents C<ASN1_INTEGER> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::ASN1_INTEGER;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::ASN1_INTEGER|SPVM::Net::SSLeay::ASN1_INTEGER> ();>

Calls native L<ASN1_INTEGER_new|https://docs.openssl.org/master/man3/ASN1_INTEGER_new> function, creates a new  L<Net::SSLeay::ASN1_INTEGER|SPVM::Net::SSLeay::ASN1_INTEGER> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

=head1 Instance Methods

=head2 get_int64

C<method get_int64 : long ();>

Calls native L<ASN1_INTEGER_get_int64|https://docs.openssl.org/master/man3/ASN1_INTEGER_get_int64> function given an appropriate argument, the pointer value of the instance, and returns the output value of the first argument.
Exceptions:

If ASN1_INTEGER_get_int64 failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_int64

C<method set_int64 : void ($r : long);>

Calls native L<ASN1_INTEGER_set_int64|https://docs.openssl.org/master/man3/ASN1_INTEGER_set_int64> function given the pointer value of the instance, $r.

Exceptions:

If ASN1_INTEGER_set_int64 failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<ASN1_INTEGER_free|https://docs.openssl.org/master/man3/ASN1_INTEGER_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

