package SPVM::Net::SSLeay::OBJ;



1;

=head1 Name

SPVM::Net::SSLeay::OBJ - OBJ Name Space in OpenSSL

=head1 Description

Net::SSLeay::OBJ class in L<SPVM> represents OBJ name space in OpenSSL

=head1 Usage

  use Net::SSLeay::OBJ;

=head1 Class Methods

=head2 txt2nid

C<static method txt2nid : int ($s : string);>

Calls native L<OBJ_txt2nid|https://docs.openssl.org/master/man3/OBJ_nid2obj> function, and returns its return value.

Exceptions:

If OBJ_txt2nid failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 nid2obj

C<static method nid2obj : L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT> ($n : int);>

Calls native L<OBJ_nid2obj|https://docs.openssl.org/master/man3/OBJ_nid2obj> function given $n, creates a new L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT>, sets the pointer value to the return value of the native function, sets C<no_free> flag of the new object to 1, and returns the new object.

Exceptions:

If OBJ_nid2obj failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 obj2nid

C<static method obj2nid : int ($o : L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT>);>

Calls native L<OBJ_obj2nid|https://docs.openssl.org/master/man3/OBJ_nid2obj> function given the pointer value of $o, and returns its return value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::PEM|SPVM::Net::SSLeay::ASN1_OBJECT>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

