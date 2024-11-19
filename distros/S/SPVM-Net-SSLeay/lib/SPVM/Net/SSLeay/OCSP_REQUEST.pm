package SPVM::Net::SSLeay::OCSP_REQUEST;



1;

=head1 Name

SPVM::Net::SSLeay::OCSP_REQUEST - OCSP_REQUEST Data Structure in OpenSSL

=head1 Description

Net::SSLeay::OCSP_REQUEST class in L<SPVM> represents L<OCSP_REQUEST|https://docs.openssl.org/1.1.1/man3/OCSP_REQUEST_new/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::OCSP_REQUEST;

=head1 Fields

=head2 ocsp_certids_list

C<has ocsp_certids_list : L<List|SPVM::List> of L<Net::SSLeay::OCSP_CERTID|SPVM::Net::SSLeay::OCSP_CERTID>;>

A list of L<Net::SSLeay::OCSP_CERTID|SPVM::Net::SSLeay::OCSP_CERTID> objects.

=head1 Class Method

=head2 new

C<static method new : L<Net::SSLeay::OCSP_REQUEST|SPVM::Net::SSLeay::OCSP_REQUEST> ($options : object[] = undef);>

Calls native L<OCSP_REQUEST_new|https://docs.openssl.org/3.0/man3/OCSP_REQUEST_new> function, creates a new L<Net::SSLeay::OCSP_REQUEST|SPVM::Net::SSLeay::OCSP_REQUEST> object, sets the pointer value of the new object to the return value of the native function, calls L</"init"> method, and returns the new object.

Exceptions:

If OCSP_REQUEST_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 init

C<protected method init : void ($options : object[] = undef);>

Creates a L<List|SPVM::List>, and sets L</"ocsp_certids_list"> field to it.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<OCSP_REQUEST_free|https://docs.openssl.org/1.1.1/man3/X509_dup> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::OCSP|SPVM::Net::SSLeay::OCSP>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

