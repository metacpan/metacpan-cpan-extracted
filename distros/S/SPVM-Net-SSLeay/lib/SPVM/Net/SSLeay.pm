package SPVM::Net::SSLeay;

our $VERSION = "0.008";

1;

=head1 Name

SPVM::Net::SSLeay - OpenSSL Binding and SSL data strcuture.

=head1 Description

Net::SSLeay class in L<SPVM> is a binding for OpenSSL. This class itself represents L<SSL|https://docs.openssl.org/master/man3/SSL_new/> data structure.

B<Warnings:>

B<The tests haven't been written yet. The features may be changed without notice.> 

=head1 Usage

  use Net::SSLeay;
  use Net::SSLeay::Net::SSLeay::SSL_METHOD;
  use Net::SSLeay::Net::SSLeay::SSL_CTX;
  
  my $ssl_method = Net::SSLeay::SSL_METHOD->SSLv23_client_method;
  
  my $ssl_ctx = Net::SSLeay::SSL_CTX->new($ssl_method);
  
  my $ssl = Net::SSLeay->new($ssl_ctx);

=head1 Examples

See source codes of L<IO::Socket::SSL|https://metacpan.org/pod/SPVM::IO::Socket::SSL> about examples of L<Net::SSLeay|SPVM::Net::SSLeay>.

=head1 Fields

=head2 operation_error

C<has operation_error : ro int;>

The place where the return value of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/>.

=head1 Class Methods

=head2 new

C<static method new : Net::SSLeay ($ssl_ctx : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>);>

Creates a new L<Net::SSLeay|SPVM::Net::SSLeay> object, creates a L<SSL|https://docs.openssl.org/master/man3/SSL_new/> object by calling L<SSL_new|https://docs.openssl.org/master/man3/SSL_new/> function given the L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object $ssl_ctx, sets the pointer value of the new L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object to the return value of L<SSL_new|https://docs.openssl.org/master/man3/SSL_new/> function, and returns the new L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object.

Exceptions:

If SSL_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 set_fd

C<method set_fd : int ($fd : int);>

Sets the file descriptor $fd as the input/output facility for the TLS/SSL (encrypted) side by calling L<SSL_set_fd|https://docs.openssl.org/master/man3/SSL_set_fd/> function, and returns its return value.

Exceptions:

If SSL_set_fd failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_tlsext_host_name

C<method set_tlsext_host_name : int ($name : string);>

Sets the server name indication ClientHello extension to contain the value name $name by calling L<SSL_set_tlsext_host_name|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_servername_callback> function.

Exceptions:

The host name $name must be defined. Otherwise an exception is thrown.

If SSL_set_tlsext_host_name failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 connect

C<method connect : int ();>

Initiates the TLS/SSL handshake with a server by calling L<SSL_connect|https://docs.openssl.org/1.0.2/man3/SSL_connect/> function, and returns its return value.

Exceptions:

If SSL_connect failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_connect|https://docs.openssl.org/1.0.2/man3/SSL_connect/> function.

=head2 accept

C<method accept : int ();>

Waits for a TLS/SSL client to initiate the TLS/SSL handshake by calling L<SSL_accept|https://docs.openssl.org/master/man3/SSL_accept/> function, and returns its return value.

Exceptions:

If SSL_accept failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_accept|https://docs.openssl.org/1.0.2/man3/SSL_accept/> function.

=head2 shutdown

C<method shutdown : int ();>

Shuts down an active connection represented by an SSL object by calling L<SSL_shutdown|https://docs.openssl.org/master/man3/SSL_shutdown/> function, and returns its return value.

Exceptions:

If SSL_shutdown failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_shutdown|https://docs.openssl.org/1.0.2/man3/SSL_shutdown/> function.

=head2 read

C<method read : int ($buf : mutable string, $num : int = -1, $offset : int = 0);>

Try to read $num bytes into the buffer $buf at the offset $offset by calling L<SSL_read|https://docs.openssl.org/1.1.1/man3/SSL_read/>, and returns its return value.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

The offset $offset must be greater than or equal to 0. Otherwise an exception is thrown.

The offset $offset + $num must be lower than or equal to the length of the buffer $buf. Otherwise an exception is thrown.

If SSL_read failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_read|https://docs.openssl.org/1.0.2/man3/SSL_read/> function.

=head2 peek

C<method peek : int ($buf : mutable string, $num : int = -1, $offset : int = 0);>

Identical to L</"read"> respectively except no bytes are actually removed from the underlying BIO during the read.

This method calls L<SSL_peek|https://docs.openssl.org/1.1.1/man3/SSL_read> function.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

The offset $offset must be greater than or equal to 0. Otherwise an exception is thrown.

The offset $offset + $num must be lower than or equal to the length of the buffer $buf. Otherwise an exception is thrown.

If SSL_peek failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_peek|https://docs.openssl.org/1.0.2/man3/SSL_peek/> function.

=head2 write

C<method write : int ($buf : string, $num : int = -1, $offset : int = 0);>

Writes $num bytes from the buffer $buf at the offset $offset into the specified ssl connection by calling L<SSL_write|https://docs.openssl.org/1.1.1/man3/SSL_write/> function, and returns its return value.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

The offset $offset must be greater than or equal to 0. Otherwise an exception is thrown.

The offset $offset + $num must be lower than or equal to the length of the buffer $buf. Otherwise an exception is thrown.

If SSL_write failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_write|https://docs.openssl.org/1.0.2/man3/SSL_write/> function.

=head2 DESTROY

C<method DESTROY : void ();>

Frees L<SSL|https://docs.openssl.org/1.0.2/man3/SSL_free> object by calling L<SSL_free|https://docs.openssl.org/1.0.2/man3/SSL_free> function if C<no_free> flag of the instance is not a true value.

=head1 Modules

=over 2

=item * L<Net::SSLeay::Constant|SPVM::Net::SSLeay::Constant>

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD>

=item * L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM>

=item * L<Net::SSLeay::X509_CRL|SPVM::Net::SSLeay::X509_CRL>

=item * L<Net::SSLeay::X509_STORE_CTX|SPVM::Net::SSLeay::X509_STORE_CTX>

=item * L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>

=item * L<Net::SSLeay::PEM|SPVM::Net::SSLeay::PEM>

=item * L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO>

=item * L<Net::SSLeay::ERR|SPVM::Net::SSLeay::ERR>

=back

=head2 Config Builder

L<SPVM::Net::SSLeay::ConfigBuilder>

=head1 Porting

This class is a Perl's L<Net::SSLeay> porting to L<SPVM>.

=head1 Repository

L<SPVM::Net::SSLeay - Github|https://github.com/yuki-kimoto/SPVM-Net-SSLeay>

=head1 Author

Yuki Kimoto<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

