package SPVM::Net::SSLeay::X509_EXTENSION;



1;

=head1 Name

SPVM::Net::SSLeay::X509_EXTENSION - X509_EXTENSION Data Structure in OpenSSL

=head1 Description

Net::SSLeay::X509_EXTENSION class in L<SPVM> represents C<X509_EXTENSION> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::X509_EXTENSION;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::X509_EXTENSION|SPVM::Net::SSLeay::X509_EXTENSION> ();>

Calls native L<X509_EXTENSION_new|https://docs.openssl.org/master/man3/X509_EXTENSION_new> function, creates a new  L<Net::SSLeay::X509_EXTENSION|SPVM::Net::SSLeay::X509_EXTENSION> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If X509_EXTENSION_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 get_data

C<method get_data : L<Net::SSLeay::ASN1_OCTET_STRING|SPVM::Net::SSLeay::ASN1_OCTET_STRING> ();>

Calls native L<X509_EXTENSION_get_data|https://docs.openssl.org/master/man3/X509_EXTENSION_get_data> functions given the pointer value of the instance, copies the return value of the native function, creates a new L<Net::SSLeay::ASN1_OCTET_STRING|SPVM::Net::SSLeay::ASN1_OCTET_STRING> object, sets the pointer value of the new object to the copied value, and returns the new object.

=head2 get_object

C<method get_object : L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT> ();>

Calls native L<X509_EXTENSION_get_object|https://docs.openssl.org/master/man3/X509_EXTENSION_get_object> functions given the pointer value of the instance, creates a new L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT>, sets the pointer value of the new object to the return value of the native function sets C<no_free> flag to 1, and returns the new object.

=head2 get_critical

C<method get_critical : int ();>

Calls native L<X509_EXTENSION_get_critical|https://docs.openssl.org/master/man3/X509_EXTENSION_get_critical> functions given the pointer value of the instance, and returns its return value.

=head2 set_object

C<method set_object : int ($obj : L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT>);>

Calls native L<X509_EXTENSION_set_object|https://docs.openssl.org/master/man3/X509_EXTENSION_set_object> functions given the pointer value of the instance, the pointer value of $obj, and returns its return value.

=head2 set_critical

C<method set_critical : int ($crit ; int);>

Calls native L<X509_EXTENSION_set_critical|https://docs.openssl.org/master/man3/X509_EXTENSION_set_critical> functions given the pointer value of the instance, $crit, and returns its return value.

=head2 set_data

C<method set_data : int ($data : L<Net::SSLeay::ASN1_OCTET_STRING|SPVM::Net::SSLeay::ASN1_OCTET_STRING>);>

Calls native L<X509_EXTENSION_set_data|https://docs.openssl.org/master/man3/X509_EXTENSION_set_data> functions given the pointer value of the instance, the pointer value of $data, and returns its return value.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<X509_EXTENSION_free|https://docs.openssl.org/master/man3/X509_EXTENSION_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

