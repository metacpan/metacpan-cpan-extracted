package SPVM::Net::SSLeay;

our $VERSION = "0.034001";

1;

=head1 Name

SPVM::Net::SSLeay - OpenSSL Binding to SPVM

=head1 Description

Net::SSLeay class in L<SPVM> is a OpenSSL binding to SPVM.

This class itself represents L<SSL|https://docs.openssl.org/master/man3/SSL> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay;
  use Net::SSLeay::Net::SSLeay::SSL_METHOD;
  use Net::SSLeay::Net::SSLeay::SSL_CTX;
  use Net::SSLeay::Constant as SSL;
  
  my $ssl_method = Net::SSLeay::SSL_METHOD->TLS_method;
  
  my $ssl_ctx = Net::SSLeay::SSL_CTX->new($ssl_method);
  
  $ssl_ctx->set_verify(SSL->SSL_VERIFY_PEER);
  
  my $ssl = Net::SSLeay->new($ssl_ctx);
  
  my $socket_fd = ...; # Get a socket file descriptor in some way.
  
  $ssl->set_fd($socket_fd);
  
  $ssl->connect;
  
  $ssl->write("foo");
  
  my $buffer = (mutable string)new_string_len 100;
  $ssl->read($buffer);
  
  $ssl->shutdown;

See also the source codes of L<IO::Socket::SSL|https://metacpan.org/pod/SPVM::IO::Socket::SSL> class to gets more examples.

=head1 Modules

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=item * L<Net::SSLeay::ASN1_ENUMERATED|SPVM::Net::SSLeay::ASN1_ENUMERATED>

=item * L<Net::SSLeay::ASN1_GENERALIZEDTIME|SPVM::Net::SSLeay::ASN1_GENERALIZEDTIME>

=item * L<Net::SSLeay::ASN1_INTEGER|SPVM::Net::SSLeay::ASN1_INTEGER>

=item * L<Net::SSLeay::ASN1_OBJECT|SPVM::Net::SSLeay::ASN1_OBJECT>

=item * L<Net::SSLeay::ASN1_OCTET_STRING|SPVM::Net::SSLeay::ASN1_OCTET_STRING>

=item * L<Net::SSLeay::ASN1_STRING|SPVM::Net::SSLeay::ASN1_STRING>

=item * L<Net::SSLeay::ASN1_TIME|SPVM::Net::SSLeay::ASN1_TIME>

=item * L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO>

=item * L<Net::SSLeay::Callback::AlpnSelect|SPVM::Net::SSLeay::Callback::AlpnSelect>

=item * L<Net::SSLeay::Callback::Msg|SPVM::Net::SSLeay::Callback::Msg>

=item * L<Net::SSLeay::Callback::PemPassword|SPVM::Net::SSLeay::Callback::PemPassword>

=item * L<Net::SSLeay::Callback::TlsextServername|SPVM::Net::SSLeay::Callback::TlsextServername>

=item * L<Net::SSLeay::Callback::Verify|SPVM::Net::SSLeay::Callback::Verify>

=item * L<Net::SSLeay::Constant|SPVM::Net::SSLeay::Constant>

=item * L<Net::SSLeay::DER|SPVM::Net::SSLeay::DER>

=item * L<Net::SSLeay::ERR|SPVM::Net::SSLeay::ERR>

=item * L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error>

=item * L<Net::SSLeay::Error::PEM_R_NO_START_LINE|SPVM::Net::SSLeay::Error::PEM_R_NO_START_LINE>

=item * L<Net::SSLeay::Error::SSL_ERROR_WANT_READ|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_READ>

=item * L<Net::SSLeay::Error::SSL_ERROR_WANT_WRITE|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_WRITE>

=item * L<Net::SSLeay::EVP|SPVM::Net::SSLeay::EVP>

=item * L<Net::SSLeay::EVP_CIPHER_CTX|SPVM::Net::SSLeay::EVP_CIPHER_CTX>

=item * L<Net::SSLeay::EVP_MD|SPVM::Net::SSLeay::EVP_MD>

=item * L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY>

=item * L<Net::SSLeay::GENERAL_NAME|SPVM::Net::SSLeay::GENERAL_NAME>

=item * L<Net::SSLeay::OBJ|SPVM::Net::SSLeay::OBJ>

=item * L<Net::SSLeay::OPENSSL|SPVM::Net::SSLeay::OPENSSL>

=item * L<Net::SSLeay::OPENSSL_INIT|SPVM::Net::SSLeay::OPENSSL_INIT>

=item * L<Net::SSLeay::OPENSSL_INIT_SETTINGS|SPVM::Net::SSLeay::OPENSSL_INIT_SETTINGS>

=item * L<Net::SSLeay::PEM|SPVM::Net::SSLeay::PEM>

=item * L<Net::SSLeay::PKCS12|SPVM::Net::SSLeay::PKCS12>

=item * L<Net::SSLeay::RAND|SPVM::Net::SSLeay::RAND>

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD>

=item * L<Net::SSLeay::Util|SPVM::Net::SSLeay::Util>

=item * L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay::X509_CRL|SPVM::Net::SSLeay::X509_CRL>

=item * L<Net::SSLeay::X509_EXTENSION|SPVM::Net::SSLeay::X509_EXTENSION>

=item * L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME>

=item * L<Net::SSLeay::X509_NAME_ENTRY|SPVM::Net::SSLeay::X509_NAME_ENTRY>

=item * L<Net::SSLeay::X509_REVOKED|SPVM::Net::SSLeay::X509_REVOKED>

=item * L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>

=item * L<Net::SSLeay::X509_STORE_CTX|SPVM::Net::SSLeay::X509_STORE_CTX>

=item * L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM>

=back

=head1 Details

=head2 Requirement

OpenSSL 1.1.1

=head2 Porting

This class is a Perl's L<Net::SSLeay> porting to L<SPVM>.

=head2 Callback Hack

OpenSSL uses a number of callback functions.

These callbacks cannot receive a L<Net::SSLeay|SPVM::Net::SSLeay> object.

So we use the following callback hack to get a L<Net::SSLeay|SPVM::Net::SSLeay> object.

Initialization:

A thread variable C<thread_env> is set to the current runtime environment.

When a new native C<SSL> object and a new L<Net::SSLeay|SPVM::Net::SSLeay> object are created at once, the new Net::SSLeay object is stored in a global L<Hash|SPVM::Hash> object keyed by the hex string of the address of the native C<SSL> object.

Getting a L<Net::SSLeay|SPVM::Net::SSLeay> Object:

The callback gets a native SSL object from the information in the arguments. And the callback gets the L<Net::SSLeay|SPVM::Net::SSLeay> object from the global L<Hash|SPVM::Hash> object using the hex string of the address of the native C<SSL> object.

Cleanup:

The key-value pair is removed by L</"DESTROY"> method in L<Net::SSLeay|SPVM::Net::SSLeay> class.

Note:

Access to the global L<Hash|SPVM::Hash> object is locked by a L<Sync::Mutex|SPVM::Sync::Mutex> object, so the access is thread-safe.

This callback hack is also used in L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> class. In this case, native C<SSL> object in the document is replaced with native C<SSL_CTX> object. And L<Net::SSLeay|SPVM::Net::SSLeay> object in the document is replaced with L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object.

=head2 Config Builder

The classes binding to OpenSSL data structures are configured by L<SPVM::Net::SSLeay::ConfigBuilder> class.

=head1 Fields

=head2 operation_error

C<has operation_error : ro int;>

The place where the return value of L<SSL_get_error|https://docs.openssl.org/master/man3/SSL_get_error> function is stored.

=head2 msg_callback

C<has msg_callback : ro L<Net::SSLeay::Callback::Msg|SPVM::Net::SSLeay::Callback::Msg>;>

A callback set by L</"set_msg_callback"> method.

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay|SPVM::Net::SSLeay> ($ssl_ctx : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>);>

Creates a new L<Net::SSLeay|SPVM::Net::SSLeay> object, calls native L<SSL_new|https://docs.openssl.org/master/man3/SSL_new> function given the pointer value of $ssl_ctx, sets the pointer value of the new object to the return value of the native function.

And calls L</"init"> method.

And returns the new L<Net::SSLeay|SPVM::Net::SSLeay> object.

Exceptions:

If SSL_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 alert_desc_string_long

C<static method alert_desc_string_long : string ($value : int);>

Calls native L<SSL_alert_desc_string_long|https://docs.openssl.org/master/man3/SSL_alert_desc_string_long> function given $value, and returns a new string created by its return value.

=head2 load_client_CA_file

C<static method load_client_CA_file : L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME>[] ($file : string);>

Calls native L<SSL_load_client_CA_file|https://docs.openssl.org/master/man3/SSL_load_client_CA_file> function given $file.

And creates a new L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> array,

And performs the following loop: copies the element at index $i of the return value(C<STACK_OF(X509_NAME)>) of the native function using native L<X509_NAME_dup|https://docs.openssl.org/master/man3/X509_NAME_dup>, creates a new L<Net::SSLeay::X509_NAME|SPVM::Net::SSLeay::X509_NAME> object, sets the pointer value of the new object to the native copied value, and puses the new object to the new array.

And returns the new array;

Exceptions:

The file $file must be defined. Otherwise an exception is thrown.

If SSL_load_client_CA_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 select_next_proto

C<static method select_next_proto : int ($out_ref : string[], $outlen_ref : byte*, $server : string, $server_len : int, $client : string, $client_len : int);>

Calls native L<SSL_select_next_proto|https://docs.openssl.org/master/man3/SSL_select_next_proto> function given the address of a native temporary variable C<out_ref>, $outlen_ref, $server, $server_len, $client, $client_len.

If a native string is returned in C<*out_ref>, creates a new string from C<*out_ref> and C<$$outlen_ref>, sets C<$out_ref-E<gt>[0]> to the new string.

And returns the return value of the native function.

Exceptions:

The output reference $out_ref must be 1-length array. Otherwise an exception is thrown.

$server must be defined. Otherwise an exception is thrown.

$client must be defined. Otherwise an exception is thrown.

=head1 Instance Methods

=head2 init

C<protected method init : void ($options : object[] = undef);>

Initializes the instance given the options $options.

Performes L<Initialization process described in Callback Hack|/"Callback Hack">.

=head2 version

C<native method version : int ();>

Calls native L<SSL_version|https://docs.openssl.org/master/man3/SSL_version> function, and returns its return value.

=head2 get_version

C<method get_version : string ();>

Calls native L<SSL_get_version|https://docs.openssl.org/master/man3/SSL_get_version> function, and returns the string created by its return value.

=head2 get_mode

C<method get_mode : long ();>

Calls native L<SSL_get_mode|https://docs.openssl.org/master/man3/SSL_get_mode> function given the pointer value of the instance, and returns its return value.

=head2 set_mode

C<method set_mode : long ($mode : long);>

Calls native L<SSL_set_mode|https://docs.openssl.org/master/man3/SSL_set_mode> function given the pointer value of the instance, $mode, and returns its return value.

=head2 clear_mode

C<method clear_mode : long ($mode : long);>

Calls native L<SSL_clear_mode|https://docs.openssl.org/master/man3/SSL_clear_mode> function given the pointer value of the instance, $mode, and returns its return value.

=head2 set_tlsext_host_name

C<method set_tlsext_host_name : int ($name : string);>

Calls native L<SSL_set_tlsext_host_name|https://docs.openssl.org/master/man3/SSL_set_tlsext_host_name> function given the pointer value of the instance, the host name $name, and returns its return value.

Exceptions:

The host name $name must be defined. Otherwise an exception is thrown.

If SSL_set_tlsext_host_name failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 get_servername

C<method get_servername : string ($type : int);>

Calls native L<SSL_get_servername|https://docs.openssl.org/master/man3/SSL_get_servername> function given the pointer value of the instance, $type.

If its return value is NULL, returns undef.

Otherwise returns the new string created from its return value.

=head2 get_SSL_CTX

C<method get_SSL_CTX : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> ();>

Calls native L<SSL_get_SSL_CTX|https://docs.openssl.org/master/man3/SSL_get_SSL_CTX> function given the pointer value of the instance, creates a new L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object, calls native L<SSL_CTX_up_ref|https://docs.openssl.org/master/man3/SSL_CTX_up_ref> function on the return value of the native function, sets the pointer value of the new object to the return value of the native function, and returns the new object.

=head2 set_SSL_CTX

C<method set_SSL_CTX : void ($ssl_ctx : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>);>

If the pointer value of $ssl_ctx is the same as the return value(named C<current_ssl_ctx>) of native L<SSL_get_SSL_CTX|https://docs.openssl.org/master/man3/SSL_get_SSL_CTX> given the pointer value of instance, does nothing.

Otherwise calls L<SSL_CTX_up_ref|https://docs.openssl.org/master/man3/SSL_CTX_up_ref> given C<current_ssl_ctx>, calls native L<SSL_set_SSL_CTX(currently not documented)|https://docs.openssl.org/master/man3/SSL_set_SSL_CTX/> function given the pointer value of the instance, the pointer value of $ssl_ctx.

If SSL_set_SSL_CTX failed, calls native L<SSL_CTX_free|https://docs.openssl.org/master/man3/SSL_CTX_free> function on C<current_ssl_ctx>.

Note:

Native SSL_set_SSL_CTX function allows $ssl_ctx to be NULL, but currently L</"set_SSL_CTX"> method does not allow undef because SSL_set_SSL_CTX is undocumented and I'm not sure how it handles reference count.

Native SSL_set_SSL_CTX function returns a native C<SSL> object, but currently the return type of L</"set_SSL_CTX"> method SSL_set_SSL_CTX is undocumented and I'm not sure how it handles reference count.

Exceptions:

The SSL_CTX object $ssl_ctx must be defined. Otherwise an exception is thrown.

If SSL_set_SSL_CTX failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_fd

C<method set_fd : int ($fd : int);>

Calls native L<SSL_set_fd|https://docs.openssl.org/master/man3/SSL_set_fd> function given the pointer value of the instance, $fd, and returns its return value.

Exceptions:

If SSL_set_fd failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 connect

C<method connect : int ();>

Calls native L<ERR_clear_error|https://docs.openssl.org/master/man3/ERR_clear_error> function.

And calls native L<SSL_connect|https://docs.openssl.org/master/man3/SSL_connect> function given the pointer value of the instance.

If SSL_connect failed, L</"operation_error"> field is set to the return vlaue(named C<ssl_operation_error>) of L<SSL_get_error|https://docs.openssl.org/master/man3/SSL_get_error> function given the return value of the native L<SSL_connect|https://docs.openssl.org/master/man3/SSL_connect> function.

And returns the return value of the native L<SSL_connect|https://docs.openssl.org/master/man3/SSL_connect> function.

Exceptions:

If SSL_connect failed, an exception is thrown with C<eval_error_id> set to the folowing value according to the error.

C<ssl_operation_error> is C<SSL_ERROR_WANT_READ>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_READ|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_READ>.

C<ssl_operation_error> is C<SSL_ERROR_WANT_WRITE>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_WRITE|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_WRITE>.

C<ssl_operation_error> is any other value, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error>.

=head2 accept

C<method accept : int ();>

Calls native L<ERR_clear_error|https://docs.openssl.org/master/man3/ERR_clear_error> function.

And calls native L<SSL_accept|https://docs.openssl.org/master/man3/SSL_accept> function given the pointer value of the instance.

If SSL_accept failed, L</"operation_error"> field is set to the return vlaue(named C<ssl_operation_error>) of L<SSL_get_error|https://docs.openssl.org/master/man3/SSL_get_error> function given the return value of the native L<SSL_accept|https://docs.openssl.org/master/man3/SSL_accept> function.

And returns the return value of the native L<SSL_accept|https://docs.openssl.org/master/man3/SSL_accept> function.

Exceptions:

If SSL_accept failed, an exception is thrown with C<eval_error_id> set to the folowing value according to the error.

C<ssl_operation_error> is C<SSL_ERROR_WANT_READ>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_READ|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_READ>.

C<ssl_operation_error> is C<SSL_ERROR_WANT_WRITE>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_WRITE|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_WRITE>.

C<ssl_operation_error> is any other value, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error>.

=head2 read

C<method read : int ($buf : mutable string, $num : int = -1, $offset : int = 0);>

Calls native L<ERR_clear_error|https://docs.openssl.org/master/man3/ERR_clear_error> function.

And calls native L<SSL_read|https://docs.openssl.org/master/man3/SSL_read> function given the pointer value of the instance, $buf at the offest $offset, $num.

If SSL_read failed, L</"operation_error"> field is set to the return vlaue(named C<ssl_operation_error>) of L<SSL_get_error|https://docs.openssl.org/master/man3/SSL_get_error> function given the return value of the native L<SSL_read|https://docs.openssl.org/master/man3/SSL_read> function.

And returns the return value of the native L<SSL_read|https://docs.openssl.org/master/man3/SSL_read> function.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

The offset $offset must be greater than or equal to 0. Otherwise an exception is thrown.

The offset $offset + $num must be lower than or equal to the length of the buffer $buf. Otherwise an exception is thrown.

If SSL_read failed, an exception is thrown with C<eval_error_id> set to the folowing value according to the error.

C<ssl_operation_error> is C<SSL_ERROR_WANT_READ>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_READ|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_READ>.

C<ssl_operation_error> is C<SSL_ERROR_WANT_WRITE>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_WRITE|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_WRITE>.

C<ssl_operation_error> is any other value, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error>.

=head2 write

C<method write : int ($buf : string, $num : int = -1, $offset : int = 0);>

Calls native L<ERR_clear_error|https://docs.openssl.org/master/man3/ERR_clear_error> function.

And calls native L<SSL_write|https://docs.openssl.org/master/man3/SSL_write> function given the pointer value of the instance, $buf at the offest $offset, $num.

If SSL_write failed, L</"operation_error"> field is set to the return vlaue(named C<ssl_operation_error>) of L<SSL_get_error|https://docs.openssl.org/master/man3/SSL_get_error> function given the return value of the native L<SSL_write|https://docs.openssl.org/master/man3/SSL_write> function.

And returns the return value of the native L<SSL_write|https://docs.openssl.org/master/man3/SSL_write> function.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

The offset $offset must be greater than or equal to 0. Otherwise an exception is thrown.

The offset $offset + $num must be lower than or equal to the length of the buffer $buf. Otherwise an exception is thrown.

If SSL_write failed, an exception is thrown with C<eval_error_id> set to the folowing value according to the error.

C<ssl_operation_error> is C<SSL_ERROR_WANT_READ>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_READ|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_READ>.

C<ssl_operation_error> is C<SSL_ERROR_WANT_WRITE>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_WRITE|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_WRITE>.

C<ssl_operation_error> is any other value, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error>.

=head2 shutdown

C<method shutdown : int ();>

Calls native L<ERR_clear_error|https://docs.openssl.org/master/man3/ERR_clear_error> function.

And calls native L<SSL_shutdown|https://docs.openssl.org/master/man3/SSL_shutdown> function given the pointer value of the instance.

If SSL_shutdown failed, L</"operation_error"> field is set to the return vlaue(named C<ssl_operation_error>) of L<SSL_get_error|https://docs.openssl.org/master/man3/SSL_get_error> function given the return value of the native L<SSL_shutdown|https://docs.openssl.org/master/man3/SSL_shutdown> function.

And returns the return value of the native L<SSL_shutdown|https://docs.openssl.org/master/man3/SSL_shutdown> function.

Exceptions:

If SSL_shutdown failed, an exception is thrown with C<eval_error_id> set to the folowing value according to the error.

C<ssl_operation_error> is C<SSL_ERROR_WANT_READ>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_READ|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_READ>.

C<ssl_operation_error> is C<SSL_ERROR_WANT_WRITE>, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error::SSL_ERROR_WANT_WRITE|SPVM::Net::SSLeay::Error::SSL_ERROR_WANT_WRITE>.

C<ssl_operation_error> is any other value, C<eval_error_id> is set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error>.

=head2 get_shutdown

C<method get_shutdown : int ();>

Calls native L<SSL_get_shutdown|https://docs.openssl.org/master/man3/SSL_get_shutdown> function, and returns its return value.

=head2 get_cipher

C<method get_cipher : string ();>

Calls native L<SSL_get_cipher|https://docs.openssl.org/master/man3/SSL_get_cipher> function, and returns the string created from its return value.

=head2 get_certificate

C<method get_certificate : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls native L<SSL_get_certificate|https://docs.openssl.org/master/man3/SSL_get_certificate> function.

If the return value of the native function is NULL, returns undef.

Otherwise, creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the new object to the return value of the native function, calls native L<X509_up_ref|https://docs.openssl.org/master/man3/X509_up_ref> function on the return value of the native function, and returns the new object.

=head2 get_peer_certificate

C<method get_peer_certificate : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls native L<SSL_get_peer_certificate|https://docs.openssl.org/master/man3/SSL_get_peer_certificate> function.

If the return value of the native function is NULL, returns undef.

Otherwise, creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

=head2 get_peer_cert_chain

C<method get_peer_cert_chain : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>[] ();>

Calls native L<SSL_get_peer_cert_chain|https://docs.openssl.org/master/man3/SSL_get_peer_cert_chain> function.

If its return value is NULL, returns undef.

Otherwise creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> array,

And performs the following loop: creates a new L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> object, calls native L<X509_up_ref|https://docs.openssl.org/master/man3/X509_up_ref> function on the element at index $i of the return value(C<STACK_OF(X509)>) of the native function, and puses the new object to the new array.

And returns the new array.

=head2 get0_alpn_selected

C<method get0_alpn_selected : void ($data_ref : string[], $len_ref : int*);>

Calls native L<SSL_get0_alpn_selected|https://docs.openssl.org/master/man3/SSL_get0_alpn_selected> function given the pointer value of the instance, the address of a native temporary variable C<data_ref>, $len_ref.

If a native string is returned in C<*data_ref>, creates a new string from C<*data_ref> and C<$$len_ref>, sets C<$data_ref-E<gt>[0]> to the new string.

Exceptions:

The data reference $data_ref must be 1-length array. Otherwise an exception is thrown.

=head2 get0_alpn_selected_return_string

C<method get0_alpn_selected_return_string : string ()>

Calls L</"get0_alpn_selected"> method given appropriate arguments, and returns C<$data_ref-E<gt>[0]>.

=head2 dump_peer_certificate

C<static method dump_peer_certificate : string ();>

Returns the same value of the return value of Perl's L<Net::SSLeay#dump_peer_certificate|https://metacpan.org/dist/Net-SSLeay/view/lib/Net/SSLeay.pod#Convenience-routines> function.

Exceptions:

The return value of get_peer_certificate method must be defined. Otherwise an exception is thrown.

=head2 set_msg_callback

C<method set_msg_callback : void ($cb : L<Net::SSLeay::Callback::Msg|SPVM::Net::SSLeay::Callback::Msg>);>

If the callback $cb is defined, A native variable C<native_cb> is set to a function pointer of the native callback funcion described below, otherwise C<native_cb> is set to NULL.

And calls native L<SSL_set_msg_callback|https://docs.openssl.org/master/man3/SSL_set_msg_callback> function given the pointer value of the instance, C<native_cb>.

And sets L</"msg_callback"> field to $cb.

Native Callback Funcion:

The native callback function is defined by the following native code:

  static void SPVM__Net__SSLeay__my__msg_callback(int write_p, int version, int content_type, const void* buf, size_t len, SSL* ssl, void* native_arg) {
    
    int32_t error_id = 0;
    
    SPVM_ENV* env = thread_env;
    
    SPVM_VALUE* stack = env->new_stack(env);
    
    int32_t scope_id = env->enter_scope(env, stack);
    
    char* tmp_buffer = env->get_stack_tmp_buffer(env, stack);
    snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", ssl);
    stack[0].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
    env->call_class_method_by_name(env, stack, "Net::SSLeay", "GET_INSTANCE", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    void* obj_self = stack[0].oval;
    
    assert(obj_self);
    
    void* obj_cb = env->get_field_object_by_name(env, stack, obj_self, "msg_callback", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    
    void* obj_buf = env->new_string(env, stack, buf, len);
    
    stack[0].oval = obj_cb;
    stack[1].ival = write_p;
    stack[2].ival = version;
    stack[3].ival = content_type;
    stack[4].oval = obj_buf;
    stack[5].ival = len;
    stack[6].oval = obj_self;
    env->call_instance_method_by_name(env, stack, "", 7, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    int32_t ret = stack[0].ival;
    
    END_OF_FUNC:
    
    env->leave_scope(env, stack, scope_id);
    
    env->free_stack(env, stack);
    
    return;
  }

=head2 DESTROY

C<method DESTROY : void ();>

Performes L<Cleanup process described in Callback Hack|/"Callback Hack">.

And calls native L<SSL_free|https://docs.openssl.org/master/man3/SSL_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

=head1 FAQ

=head2 Is LibreSSL supported?

Yes.

=head1 See Also

=over 2

=item * L<IO::Socket::SSL|https://metacpan.org/pod/SPVM::IO::Socket::SSL>

=back

=head1 Repository

L<SPVM::Net::SSLeay - Github|https://github.com/yuki-kimoto/SPVM-Net-SSLeay>

=head1 Author

Yuki Kimoto<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

