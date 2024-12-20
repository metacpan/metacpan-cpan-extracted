package SPVM::Net::SSLeay::X509_NAME;



1;

=head1 Name

SPVM::Net::SSLeay::X509_NAME - X509_NAME Data Structure in OpenSSL

=head1 Description

Net::SSLeay::X509_NAME class in L<SPVM> represents C<X509_NAME> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::X509_NAME;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> ();>

Calls native L<X509_NAME_new|https://docs.openssl.org/master/man3/X509_NAME_new> function, creates a new  L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If X509_NAME_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 oneline

C<method oneline : string ();>

Calls native L<X509_NAME_oneline|https://docs.openssl.org/master/man3/X509_NAME_oneline> functions given the pointer value of the instance, $buf with NULL, and returns its return value.

=head2 get_entry

C<method get_entry : L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> ($loc : int);>

Calls native L<X509_NAME_get_entry|https://docs.openssl.org/master/man3/X509_NAME_get_entry> functions given the pointer value of the instance, $loc, creates a new L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> object, copies the return value of the native function using native L<X509_NAME_ENTRY_dup|https://docs.openssl.org/master/man3/X509_NAME_ENTRY_dup> function, sets the pointer value of the new object to the copied value, and returns the new object.

=head2 get_index_by_NID

C<method get_index_by_NID : int ($nid : int, $lastpos : int);>

Calls native L<X509_NAME_get_index_by_NID|https://docs.openssl.org/master/man3/X509_NAME_get_index_by_NID> functions given the pointer value of the instance, $nid, $lastpos, and returns its return value.

=head2 entry_count

C<method entry_count : int ();>

Calls native L<X509_NAME_entry_count|https://docs.openssl.org/master/man3/X509_NAME_entry_count> functions given the pointer value of the instance, and returns its return value.

=head2 add_entry_by_NID

C<method add_entry_by_NID : int ($nid : int, $type : int, $bytes : string, $len : int = -1, $loc : int = -1, $set : int = 0);>

Calls native L<X509_NAME_add_entry_by_NID|https://docs.openssl.org/master/man3/X509_NAME_add_entry_by_NID> functions given the pointer value of the instance, $nid, $type, $bytes, $len, $loc, $set, and returns its return value.

Exceptions:

The bytes $bytes must be defined. Otherwise an exception is thrown.

If X509_NAME_add_entry_by_NID failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 delete_entry

C<method delete_entry : L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> ($loc : int);>

Calls native L<X509_NAME_delete_entry|https://docs.openssl.org/master/man3/X509_NAME_delete_entry> functions given the pointer value of the instance, $loc, creates a new L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY> object, sets the pointer value of the new object to the return value of the native function,, and returns the new object.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<X509_NAME_free|https://docs.openssl.org/master/man3/X509_NAME_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

