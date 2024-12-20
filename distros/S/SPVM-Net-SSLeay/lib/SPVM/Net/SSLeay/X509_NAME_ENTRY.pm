package SPVM::Net::SSLeay::X509_NAME_ENTRY;



1;

=head1 Name

SPVM::Net::SSLeay::X509_NAME_ENTRY - X509_NAME_ENTRY Data Structure in OpenSSL

=head1 Description

Net::SSLeay::X509_NAME_ENTRY class in L<SPVM> represents C<X509_NAME_ENTRY> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::X509_NAME_ENTRY;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> ();>

Calls native L<X509_NAME_ENTRY_new|https://docs.openssl.org/master/man3/X509_NAME_ENTRY_new> function, creates a new  L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If X509_NAME_ENTRY_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 get_data

C<method get_data : L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> ();>

Calls native L<X509_NAME_ENTRY_get_data|https://docs.openssl.org/master/man3/X509_NAME_ENTRY_get_data> functions given the pointer value of the instance, copies the return value of the native function, creates a new L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> object, sets the pointer value of the new object to the copied value, and returns the new object.

=head2 get_object

C<method get_object : L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT> ();>

Calls native L<X509_NAME_ENTRY_get_object|https://docs.openssl.org/master/man3/X509_NAME_ENTRY_get_object> functions given the pointer value of the instance, creates a new L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT>, sets the pointer value of the new object to the return value of the native function sets C<no_free> flag to 1, and returns the new object.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<X509_free|https://docs.openssl.org/master/man3/X509_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

=head1 FAQ

=head2 How to convert a Net::SSLeay::ASN1_OBJECT object to NID?

Use L<Net::SSLeay::OBJ#obj2nid|SPVM::Net::SSLeay::OBJ/"obj2nid"> method.

=head1 See Also

=over 2

=item * L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME>

=item * L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay::OBJ|SPVM::Net::SSLeay::OBJ>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

