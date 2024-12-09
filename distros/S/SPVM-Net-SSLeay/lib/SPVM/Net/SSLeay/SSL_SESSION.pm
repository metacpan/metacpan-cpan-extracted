package SPVM::Net::SSLeay::SSL_SESSION;



1;

=head1 Name

SPVM::Net::SSLeay::SSL_SESSION - SSL_SESSION Data Strucutre in OpenSSL

=head1 Description

Net::SSLeay::SSL_SESSION class in L<SPVM> represents  L<SSL_SESSION|https://docs.openssl.org/1.1.1/man3/SSL_SESSION_free/> data strucutre in OpenSSL.

=head1 Usage

  use Net::SSLeay::SSL_SESSION;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::SSL_SESSION|SPVM::Net::SSLeay::SSL_SESSION> ();>

Calls native L<SSL_SESSION_new|https://docs.openssl.org/1.0.2/man3/SSL_SESSION_new/> function, creates a new  L<Net::SSLeay::SSL_SESSION|SPVM::Net::SSLeay::SSL_SESSION> object, sets the pointer value of the object to the return value of the native function, and returns the new object.

Exceptions:

If SSL_SESSION_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<SSL_SESSION_free|https://docs.openssl.org/1.1.1/man3/SSL_SESSION_free/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

