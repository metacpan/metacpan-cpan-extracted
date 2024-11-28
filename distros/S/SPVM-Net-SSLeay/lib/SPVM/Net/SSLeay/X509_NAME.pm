package SPVM::Net::SSLeay::X509_NAME;



1;

=head1 Name

SPVM::Net::SSLeay::X509_NAME - X509_NAME Data Structure in OpenSSL

=head1 Description

Net::SSLeay::X509_NAME class in L<SPVM> represents L<X509_NAME|https://docs.openssl.org/3.3/man3/X509_dup/> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::X509_NAME;

=head1 Instance Methods

=head2 oneline

C<method oneline : string ();>

Calls native L<X509_NAME_oneline|https://docs.openssl.org/1.1.1/man3/X509_NAME_print_ex> functions given the pointer value of the instance, $buf with NULL, and returns its return value.

=head2 get_text_by_NID

C<method get_text_by_NID : int ($nid : int, $buf : mutable string, $len : int = -1);>

Calls native L<X509_NAME_get_text_by_NID|https://docs.openssl.org/1.1.1/man3/X509_NAME_get_index_by_NID> functions given the pointer value of the instance, $nid, $buf, $len, and returns its return value.

If $buf is defined and $len is a negative value, $len is set to the length of $buf.

=head2 get_entry

C<method get_entry : L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> ($loc : int);>

Calls native L<X509_NAME_get_entry|https://docs.openssl.org/3.1/man3/X509_NAME_get_index_by_NID> functions given the pointer value of the instance, $loc, creates a new L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> object, sets the pointer value of the new object to the return value of the native function, sets C<no_free> flag of the new object to 1, and returns the new object.

=head2 get_index_by_NID

C<method get_index_by_NID : int ($nid : int, $lastpos : int);>

Calls native L<X509_NAME_get_index_by_NID|https://docs.openssl.org/1.1.1/man3/X509_NAME_get_index_by_NID> functions given the pointer value of the instance, $nid, $lastpos, and returns its return value.

=head2 entry_count

C<method entry_count : int ();>

Calls native L<X509_NAME_entry_count|https://docs.openssl.org/1.1.1/man3/X509_NAME_get_index_by_NID> functions given the pointer value of the instance, and returns its return value.

=head2 get_index_by_OBJ

C<method get_index_by_OBJ : int ($obj : Net::SSLeay::ASN1_OBJECT, $lastpos : int);>

Calls native L<X509_NAME_get_index_by_OBJ|https://docs.openssl.org/1.1.1/man3/X509_NAME_get_index_by_NID> functions given the pointer value of the instance, the pointer value of $obj, $lastpos, and returns its return value.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<X509_NAME_free|https://docs.openssl.org/3.3/man3/X509_dup/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::PEM|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

