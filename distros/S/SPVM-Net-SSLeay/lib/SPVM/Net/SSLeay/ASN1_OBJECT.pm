package SPVM::Net::SSLeay::ASN1_OBJECT;



1;

=head1 Name

SPVM::Net::SSLeay::ASN1_OBJECT - ASN1_OBJECT Data Structure in OpenSSL

=head1 Description

Net::SSLeay::ASN1_OBJECT class in L<SPVM> represents C<ASN1_OBJECT> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::ASN1_OBJECT;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::OBJECT|SPVM::Net::SSLeay::OBJECT> ();>

Calls native L<ASN1_OBJECT_new|https://docs.openssl.org/master/man3/ASN1_OBJECT_new> function, creates a new  L<Net::SSLeay::OBJECT|SPVM::Net::SSLeay::OBJECT> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If ASN1_OBJECT_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<ASN1_OBJECT_free|https://docs.openssl.org/master/man3/ASN1_OBJECT_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::OBJ|SPVM::Net::SSLeay::OBJ>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

