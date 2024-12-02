package SPVM::Net::SSLeay::ASN1_TIME;



1;

=head1 Name

SPVM::Net::SSLeay::ASN1_TIME - ASN1_TIME Data Structure in OpenSSL

=head1 Description

Net::SSLeay::ASN1_TIME class in L<SPVM> represents L<ASN1_TIME|https://docs.openssl.org/3.2/man3/ASN1_TIME_set> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::ASN1_TIME;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::ASN1_TIME|SPVM::Net::SSLeay::ASN1_TIME> ();>

Calls native L<ASN1_TIME_new|https://docs.openssl.org/1.0.2/man3/ASN1_TIME_new/> function, creates a new  L<Net::SSLeay::ASN1_TIME|SPVM::Net::SSLeay::ASN1_TIME> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If ASN1_TIME_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 set

C<static method set : void ($t : long);>

Calls native L<ASN1_TIME_set|https://docs.openssl.org/1.1.1/man3/ASN1_TIME_set> function given the pointer value of the instance, $t.

Exceptions:

If ASN1_TIME_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 check

C<method check : int ();>

Calls native L<ASN1_TIME_check|https://docs.openssl.org/1.1.1/man3/ASN1_TIME_set> function given the pointer value of the instance, and returns its return value.

=head2 print

C<method print : int ($b : L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO>);>

Calls native L<ASN1_TIME_print|https://docs.openssl.org/1.1.1/man3/ASN1_TIME_set> function given $b, the pointer value of the instance.

Exceptions:

If ASN1_TIME_print failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 to_tm

C<method to_tm : int ($tm : L<Sys::Time::Tm|SPVM::Sys::Time::Tm>);>

Calls native L<ASN1_TIME_to_tm|https://docs.openssl.org/1.1.1/man3/ASN1_TIME_set> function given the pointer value of the instance, $tm.

Exceptions:

If ASN1_TIME_to_tm failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 to_generalizedtime

C<method to_generalizedtime : L<Net::SSLeay::ASN1_GENERALIZEDTIME|SPVM::Net::SSLeay::ASN1_GENERALIZEDTIME> ();>

Calls native L<ASN1_TIME_to_generalizedtime|https://docs.openssl.org/1.1.1/man3/ASN1_TIME_set> function given the pointer value of the instance, NULL, creates a new L<Net::SSLeay::ASN1_GENERALIZEDTIME|SPVM::Net::SSLeay::ASN1_GENERALIZEDTIME>, sets the pointer value of the new object to the return value of the native function, and returns the new object.

Exceptions:

If ASN1_TIME_to_generalizedtime failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<ASN1_TIME_free|https://pub.sortix.org/sortix/release/nightly/man/man3/ASN1_TIME_free.3.html> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

