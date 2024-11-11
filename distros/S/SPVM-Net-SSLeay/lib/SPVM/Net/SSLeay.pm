package SPVM::Net::SSLeay;

our $VERSION = "0.010";

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

=head2 ssl_ctx

C<has ssl_ctx : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>;>

A L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object.

=head2 operation_error

C<has operation_error : ro int;>

The place where the return value of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function is stored.

=head1 Class Methods

=head2 new

C<static method new : Net::SSLeay ($ssl_ctx : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>);>

Creates a new L<Net::SSLeay|SPVM::Net::SSLeay> object, creates a L<SSL|https://docs.openssl.org/master/man3/SSL_new/> object by calling native L<SSL_new|https://docs.openssl.org/master/man3/SSL_new/> function given the L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object $ssl_ctx, sets the pointer value of the new L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object to the return value of L<SSL_new|https://docs.openssl.org/master/man3/SSL_new/> function, and returns the new L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object.

L</"ssl_ctx"> field is set to $ssl_ctx.

Exceptions:

If SSL_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 library_init

C<static method library_init : int ();>

Calls native L<SSL_library_init|https://docs.openssl.org/master/man3/SSL_library_init> function, and returns its return value.

=head2 load_error_strings

C<static method load_error_strings : void ();>

Calls native L<SSL_load_error_strings|https://docs.openssl.org/3.0/man3/ERR_load_crypto_strings/> function.

=head1 Instance Methods

=head2 set_fd

C<method set_fd : int ($fd : int);>

Calls native L<SSL_set_fd|https://docs.openssl.org/master/man3/SSL_set_fd/> function given $fd, and returns its return value.

Exceptions:

If SSL_set_fd failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_tlsext_host_name

C<method set_tlsext_host_name : int ($name : string);>

Calls native L<SSL_set_tlsext_host_name|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_servername_callback> function given the host name $name, and returns its return value.

Exceptions:

The host name $name must be defined. Otherwise an exception is thrown.

If SSL_set_tlsext_host_name failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 connect

C<method connect : int ();>

Calls native L<SSL_connect|https://docs.openssl.org/1.0.2/man3/SSL_connect/> function, and returns its return value.

Exceptions:

If SSL_connect failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_connect|https://docs.openssl.org/1.0.2/man3/SSL_connect/> function.

=head2 accept

C<method accept : int ();>

Calls native L<SSL_accept|https://docs.openssl.org/master/man3/SSL_accept/> function, and returns its return value.

Exceptions:

If SSL_accept failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_accept|https://docs.openssl.org/1.0.2/man3/SSL_accept/> function.

=head2 shutdown

C<method shutdown : int ();>

Calls native L<SSL_shutdown|https://docs.openssl.org/master/man3/SSL_shutdown/> function, and returns its return value.

Exceptions:

If SSL_shutdown failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_shutdown|https://docs.openssl.org/1.0.2/man3/SSL_shutdown/> function.

=head2 read

C<method read : int ($buf : mutable string, $num : int = -1, $offset : int = 0);>

Calls native L<SSL_read|https://docs.openssl.org/1.1.1/man3/SSL_read/> function given $buf at the offest $offset, $num, and returns its return value.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

The offset $offset must be greater than or equal to 0. Otherwise an exception is thrown.

The offset $offset + $num must be lower than or equal to the length of the buffer $buf. Otherwise an exception is thrown.

If SSL_read failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_read|https://docs.openssl.org/1.0.2/man3/SSL_read/> function.

=head2 peek

C<method peek : int ($buf : mutable string, $num : int = -1, $offset : int = 0);>

Calls native L<SSL_peek|https://docs.openssl.org/1.1.1/man3/SSL_peek/> function given $buf at the offset $offset, $num, and returns its return value.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

The offset $offset must be greater than or equal to 0. Otherwise an exception is thrown.

The offset $offset + $num must be lower than or equal to the length of the buffer $buf. Otherwise an exception is thrown.

If SSL_peek failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_peek|https://docs.openssl.org/1.0.2/man3/SSL_peek/> function.

=head2 write

C<method write : int ($buf : string, $num : int = -1, $offset : int = 0);>

Calls native L<SSL_write|https://docs.openssl.org/1.1.1/man3/SSL_write/> function, given $buf at the offset $offset, $num, and returns its return value.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

The offset $offset must be greater than or equal to 0. Otherwise an exception is thrown.

The offset $offset + $num must be lower than or equal to the length of the buffer $buf. Otherwise an exception is thrown.

If SSL_write failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class and with L</"operation_error"> field set to the return vlaue of L<SSL_get_error|https://docs.openssl.org/1.1.1/man3/SSL_get_error/> function given the return value of L<SSL_write|https://docs.openssl.org/1.0.2/man3/SSL_write/> function.

=head2 get_servername

C<method get_servername : string ($type : int);>

Calls native L<SSL_get_servername|https://docs.openssl.org/master/man3/SSL_CTX_set_tlsext_servername_callback> function given $type, and returns its return value.

=head2 set_tlsext_status_type

C<method set_tlsext_status_type : long  ($type : int);>

Calls native L<SSL_set_tlsext_status_type|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_tlsext_status_cb> function given $type, and returns its return value.

Exceptions:

If SSL_set_tlsext_status_type failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 alert_desc_string_long

C<method alert_desc_string_long : string  ($type : int);>

Calls native L<SSL_alert_desc_string_long|https://docs.openssl.org/1.1.1/man3/SSL_alert_type_string/> function given $type, and returns its return value.

=head2 set_mode

C<method set_mode : long ($mode : long);>

Calls native L<SSL_set_mode|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_mode/> function given $mode, and returns its return value.

=head2 clear_mode

C<method clear_mode : long ($mode : long);>

Calls native L<SSL_clear_mode|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_mode/> function given $mode, and returns its return value.

=head2 get_mode

C<method get_mode : long ();>

Calls native L<get_mode|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_mode/> function, and returns its return value.

=head2 version

C<native method version : int ();>

Calls native L<version|https://docs.openssl.org/master/man3/SSL_get_version> function, and returns its return value.

=head2 session_reused

C<native method session_reused : int ();>
  
Calls native L<SSL_session_reused|https://docs.openssl.org/1.1.1/man3/SSL_session_reused/> function, and returns its return value.

=head2 get_cipher

C<method get_cipher : string ();>

Calls native L<SSL_get_cipher|https://docs.openssl.org/1.0.2/man3/SSL_get_current_cipher/> function, and returns its return value.

=head2 get_peer_certificate

C<method get_peer_certificate : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls native L<SSL_get_peer_certificate|https://docs.openssl.org/master/man3/SSL_get_peer_certificate> function.

If the return value of the native function is NULL, returns undef.

Otherwise, creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

=head2 get_shutdown

C<method get_shutdown : int ();>

Calls native L<SSL_get_shutdown|https://docs.openssl.org/master/man3/SSL_set_shutdown/> function, and returns its return value.

=head2 pending

C<method pending : int ();>

Calls native L<SSL_pending|https://docs.openssl.org/master/man3/SSL_pending/> function, and returns its return value.

=head2 get1_session

C<method get1_session : L<Net::SSLeay::SSL_SESSION|SPVM::Net::SSLeay::SSL_SESSION> ();>

Calls native L<SSL_get1_session|https://docs.openssl.org/1.1.1/man3/SSL_get_session> function.

If the return value of the native function is NULL, returns undef.

Otherwise, creates a new L<Net::SSLeay::SSL_SESSION|SPVM::Net::SSLeay::SSL_SESSION> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

=head2 set_session

C<method set_session : int ($session : Net::SSLeay::SSL_SESSION);>

Calls native L<SSL_set_session|https://docs.openssl.org/1.1.1/man3/SSL_set_session> function given the pointer value of $session, sets L</"ssl_session"> field to $ssl.

If this method succeeds, C<no_free> flag of $session is set to 1.

Exceptions:

If SSL_set_session failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 DESTROY

C<method DESTROY : void ();>

Frees native L<SSL|https://docs.openssl.org/1.0.2/man3/SSL_free> object by calling native L<SSL_free|https://docs.openssl.org/1.0.2/man3/SSL_free> function if C<no_free> flag of the instance is not a true value.

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

