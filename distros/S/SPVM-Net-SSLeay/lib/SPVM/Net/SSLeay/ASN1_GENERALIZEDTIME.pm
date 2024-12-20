package SPVM::Net::SSLeay::ASN1_GENERALIZEDTIME;



1;

=head1 Name

SPVM::Net::SSLeay::ASN1_GENERALIZEDTIME - ASN1_GENERALIZEDTIME Data Structure in OpenSSL

=head1 Description

Net::SSLeay::ASN1_GENERALIZEDTIME class in L<SPVM> represents C<ASN1_GENERALIZEDTIME> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::ASN1_GENERALIZEDTIME;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::ASN1_GENERALIZEDTIME|SPVM::Net::SSLeay::ASN1_GENERALIZEDTIME> ();>

Calls native L<ASN1_GENERALIZEDTIME_new|https://docs.openssl.org/master/man3/ASN1_GENERALIZEDTIME_new> function, creates a new  L<Net::SSLeay::ASN1_GENERALIZEDTIME|SPVM::Net::SSLeay::ASN1_GENERALIZEDTIME> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If ASN1_GENERALIZEDTIME_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 set

C<static method set : void ($t : long);>

Calls native L<ASN1_GENERALIZEDTIME_set|https://docs.openssl.org/master/man3/ASN1_GENERALIZEDTIME_set> function given the pointer value of the instance, $t.

Exceptions:

If ASN1_GENERALIZEDTIME_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 check

C<method check : int ();>

Calls native L<ASN1_GENERALIZEDTIME_check|https://docs.openssl.org/master/man3/ASN1_GENERALIZEDTIME_check> function given the pointer value of the instance, and returns its return value.

=head2 print

C<method print : int ($b : L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO>);>

Calls native L<ASN1_GENERALIZEDTIME_print|https://docs.openssl.org/master/man3/ASN1_GENERALIZEDTIME_print> function given $b, the pointer value of the instance.

Exceptions:

If ASN1_GENERALIZEDTIME_print failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<ASN1_GENERALIZEDTIME_free|https://docs.openssl.org/master/man3/ASN1_GENERALIZEDTIME_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

