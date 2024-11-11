package SPVM::Net::SSLeay::EC_KEY;



1;

=head1 Name

SPVM::Net::SSLeay::EC_KEY - EC_KEY Data Strucutre in OpenSSL

=head1 Description

Net::SSLeay::EC_KEY class in L<SPVM> represents L<EC_KEY|https://docs.openssl.org/master/man3/EC_KEY_new/> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::EC_KEY;

=head1 Class Methods

=head2 new_by_curve_name

C<method new_by_curve_name : Net::SSLeay::EC_KEY ($nid : int);>

Calls native L<EC_KEY_new_by_curve_name|https://docs.openssl.org/1.1.1/man3/EC_KEY_new/> function given $nid, creates a new L<Net::SSLeay::EC_KEY|SPVM::Net::SSLeay::EC_KEY> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

Exceptions:

If EC_KEY_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Frees native L<EC_KEY|https://docs.openssl.org/master/man3/EC_KEY_new/> object by calling native L<EC_KEY_free|https://docs.openssl.org/master/man3/EC_KEY_new/> function if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

