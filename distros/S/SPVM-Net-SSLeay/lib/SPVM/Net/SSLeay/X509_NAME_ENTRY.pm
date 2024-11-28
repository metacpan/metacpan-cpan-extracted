package SPVM::Net::SSLeay::X509_NAME_ENTRY;



1;

=head1 Name

SPVM::Net::SSLeay::X509_NAME_ENTRY - X509_NAME_ENTRY Data Structure in OpenSSL

=head1 Description

Net::SSLeay::X509_NAME_ENTRY class in L<SPVM> represents L<X509_NAME_ENTRY|https://docs.openssl.org/3.2/man3/X509_new/> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::X509_NAME_ENTRY;

=head1 Fields

=head2 ref_x509_name

C<has ref_x509_name : L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME>;>

=head1 Instance Methods

=head2 get_data

C<method get_data : L<Net::SSLeay::ASN1_STRING|SPVM::Net::SSLeay::ASN1_STRING> ();>

Calls native L<X509_NAME_ENTRY_get_data|https://docs.openssl.org/1.1.1/man3/X509_NAME_ENTRY_get_object> functions given the pointer value of the instance, copies the return value of the native function, creates a new L<Net::SSLeay::ASN1_STRING|SPVM::Net::SSLeay::ASN1_STRING> object, sets the pointer value of the new object to the copied value, and returns the new object.

=head2 get_object

C<method get_object : L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT> ();>

Calls native L<X509_NAME_ENTRY_get_object|https://docs.openssl.org/1.1.1/man3/X509_NAME_ENTRY_get_object> functions given the pointer value of the instance, creates a new L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT>, sets the pointer value of the new object to the return value of the native function sets C<no_free> flag to 1, and returns the new object.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<X509_free|https://docs.openssl.org/3.2/man3/X509_new> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::PEM|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

