package SPVM::IO::Socket::SSL;

our $VERSION = "0.006";

1;

=head1 Name

SPVM::IO::Socket::SSL - Sockets for SSL Communication.

=head1 Description

B<This class is highly experimental and not yet implemented completly and not tested well and not yet documented.>

IO::Socket::SSL class in L<SPVM> represents sockets for SSL communication.

=head1 Usage

  use IO::Socket::SSL;
  
  # Client
  my $host = "www.google.com";
  my $port = 443;
  my $socket = IO::Socket::SSL->new({PeerAddr => $host, PeerPort => $port});
  
  my $write_buffer = "GET / HTTP/1.0\r\nHost: $host\r\n\r\n";
  $socket->write($write_buffer);
  
  my $read_buffer = (mutable string)new_string_len 100000;
  while (1) {
    my $read_length = $socket->read($read_buffer);
    
    if ($read_length < 0) {
      die "Read error";
    }
    
    if ($read_length < length $read_buffer) {
      last;
    }
  }
  
  # Server
  my $server_socket = IO::Socket::SSL->new({
    Listen => 10,
  });
  $server_socket->accept;
  
=head1 Super Class

L<IO::Socket::IP|SPVM::IO::Socket::IP>

=head1 Fields

=head2 ssl_ctx

C<has ssl_ctx : ro L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>;>

A L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object.

=head2 ssl

C<has ssl : ro L<Net::SSLeay|SPVM::Net::SSLeay>;>

A L<Net::SSLeay|SPVM::Net::SSLeay> object. This object is set after L</"connect_SSL"> method or L</"accept_SSL"> method succeeds.

=head2 before_connect_SSL_cbs_list

C<has before_connect_SSL_cbs_list : ro List of L<IO::Socket::SSL::Callback::BeforeConnectSSL|SPVM::IO::Socket::SSL::Callback::BeforeConnectSSL>;>

=head2 before_accept_SSL_cbs_list

C<has before_accept_SSL_cbs_list : ro List of L<IO::Socket::SSL::Callback::BeforeAcceptSSL|SPVM::IO::Socket::SSL::Callback::BeforeAcceptSSL>;>

=head2 SSL_verify_mode

C<has SSL_verify_mode : int;>

=head2 SSL_verify_callback

C<has SSL_verify_callback : L<Net::SSLeay::Callback::Verify|SPVM::Net::SSLeay::Callback::Verify>;>

=head2 SSL_hostname

C<has SSL_hostname : string;>

=head2 SSL_cipher_list

C<has SSL_cipher_list : string;>

=head2 SSL_ciphersuites

C<has SSL_ciphersuites : string;>

=head2 SSL_check_crl

C<has SSL_check_crl : int;>

=head2 SSL_crl_file

C<has SSL_crl_file : string;>

=head2 SSL_server

C<has SSL_server : int;>

=head2 SSL_server_specified

C<has SSL_server_specified : int;>

=head2 SSL_alpn_protocols

C<has SSL_alpn_protocols : string[];>

=head2 SSL_startHandshake

C<has SSL_startHandshake : int;>

=head2 SSL_honor_cipher_order

C<has SSL_honor_cipher_order : int;>

=head2 SSL_ca_file

C<has SSL_ca_file : string;>

=head2 SSL_ca_path

C<has SSL_ca_path : string;>

=head2 SSL_ca

C<has SSL_ca : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>[];>

=head2 SSL_cert_file

C<has SSL_cert_file : string;>

=head2 SSL_cert

C<has SSL_cert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>[];>

=head2 SSL_key_file

C<has SSL_key_file : string;>

=head2 SSL_key

C<has SSL_key : L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY>;>

=head1 Class Methods

=head2 new

C<static method new : IO::Socket::SSL ($options : object[] = undef);>
  
=head1 Instance Methods

=head2 option_names

C<protected method option_names : string[] ();>

=head2 init

C<protected method init : void ($options : object[] = undef);>

Options:

=over 2

=item * SSL_verify_mode : Int

=item * SSL_verify_callback : L<Net::SSLeay::Callback::Verify|SPVM::Net::SSLeay::Callback::Verify> = undef

=item * SSL_hostname : string

=item * SSL_cipher_list : string

=item * SSL_ciphersuites : string

=item * SSL_check_crl : Int

=item * SSL_crl_file : string

=item * SSL_server : Int

=item * SSL_alpn_protocols : string[]

=item * SSL_startHandshake : Int = 1

=item * SSL_honor_cipher_order : Int = 0;

=item * SSL_ca_file : string = undef

=item * SSL_ca_path : string = undef

=item * SSL_ca : Net::SSLeay::X509[] = undef

=item * SSL_cert_file : string = undef

=item * SSL_cert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>[] = undef

=item * SSL_key_file : string = undef

=item * SSL_key : L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY> = undef

=back

=head2 configure

C<protected method configure : void ();>

=head2 configure_SSL

C<protected method configure_SSL : void ();>

=head2 connect_SSL

C<method connect_SSL : void ();>

=head2 accept_SSL

C<method accept_SSL : void ();>

=head2 accept

C<method accept : IO::Socket::SSL ($peer_ref : Sys::Socket::Sockaddr[] = undef);>

=head2 read

C<method read : int ($buffer : mutable string, $length : int = -1, $offset : int = 0);>

=head2 write

C<method write : int ($buffer : string, $length : int = -1, $offset : int = 0);>

=head2 shutdown_SSL

C<method shutdown_SSL : int ();>

=head2 close

C<method close : void ();>

=head2 dump_peer_certificate

C<method dump_peer_certificate : string ();>

Calls L<Net::SSLeay#dump_peer_certificate|SPVM::Net::SSLeay/"dump_peer_certificate"> method given the value of L</"ssl"> field, and returns its return value.

Exceptions:

Exceptions thrown by L<Net::SSLeay#dump_peer_certificate|SPVM::Net::SSLeay/"dump_peer_certificate"> method could be thrown.

=head2 alpn_selected

C<method alpn_selected : string ();>

Calls L<Net::SSLeay#get0_alpn_selected|SPVM::Net::SSLeay/"get0_alpn_selected"> method given appropriate arguments, converts the value of output argument to a string of appropriate length, and retunrs it.

=head2 get_sslversion

C<method get_sslversion : string ();>

Returns the same output of Perl's L<IO::Socket::SSL|/"get_sslversion"> method.

Exceptions:

If the version number is unknown, an exception is thrown.

=head2 get_sslversion_int

C<method get_sslversion_int : int ();>

Calls L<Net::SSLeay#version|SPVM::Net::SSLeay/"version"> method given the value of L</"ssl"> field, and returns its return value.

=head2 get_cipher

C<method get_cipher : string ();>

Calls L<Net::SSLeay#get_cipher|SPVM::Net::SSLeay/"get_cipher"> method given the value of L</"ssl"> field, and returns its return value.

Exceptions:

Exceptions thrown by L<Net::SSLeay#get_cipher|SPVM::Net::SSLeay/"get_cipher"> method could be thrown.

=head2 get_servername

C<method get_servername : string ();>

Calls L<Net::SSLeay#get_servername|SPVM::Net::SSLeay/"get_servername"> method given the value of L</"ssl"> field, the value of C<TLSEXT_NAMETYPE_host_name>, and returns its return value.

Exceptions:

Exceptions thrown by L<Net::SSLeay#get_servername|SPVM::Net::SSLeay/"get_servername"> method could be thrown.

=head2 peer_certificate

C<method peer_certificate : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls L<Net::SSLeay#get1_peer_certificate|SPVM::Net::SSLeay/"get1_peer_certificate"> method given the value of L</"ssl"> field, and returns its return value.

Exceptions:

Exceptions thrown by L<Net::SSLeay#get1_peer_certificate|SPVM::Net::SSLeay/"get1_peer_certificate"> method could be thrown.

=head2 peer_certificates

C<method peer_certificates : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>[];>

Returns the same output of Perl's L<IO::Socket::SSL|/"peer_certificates"> method.

=head2 sock_certificate

C<method sock_certificate : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> ();>

Calls L<Net::SSLeay#get_certificate|SPVM::Net::SSLeay/"get_certificate"> method given the value of L</"ssl"> field, and returns its return value.

Exceptions:

Exceptions thrown by L<Net::SSLeay#get_certificate|SPVM::Net::SSLeay/"get_certificate"> method could be thrown.

=head2 add_before_connect_SSL_cb

C<method add_before_connect_SSL_cb : void ($cb : L<IO::Socket::SSL::Callback::BeforeConnectSSL|SPVM::IO::Socket::SSL::Callback::BeforeConnectSSL>);>

=head2 add_before_accept_SSL_cb

C<method add_before_accept_SSL_cb : void ($cb : L<IO::Socket::SSL::Callback::BeforeAcceptSSL|SPVM::IO::Socket::SSL::Callback::BeforeAcceptSSL>);>

=head2 stat

C<method stat : L<Sys::IO::Stat|SPVM::Sys::IO::Stat> ();>

This method is not supported in L<IO::Socket::SSL|SPVM::IO::Socket::SSL>.

Exceptions:

An exception is thrown.

=head2 send

C<method send : int ($buffer : string, $flags : int = 0, $length : int = -1, $offset : int = 0);>

This method is not supported in L<IO::Socket::SSL|SPVM::IO::Socket::SSL>.

Exceptions:

An exception is thrown.

=head2 sendto

C<method sendto : int ($buffer : string, $flags : int, $to : Sys::Socket::Sockaddr, $length : int = -1, $offset : int = 0);>

This method is not supported in L<IO::Socket::SSL|SPVM::IO::Socket::SSL>.

Exceptions:

An exception is thrown.

=head2 recv

C<method recv : int ($buffer : mutable string, $length : int = -1, $flags : int = 0, $offset : int = 0);>

This method is not supported in L<IO::Socket::SSL|SPVM::IO::Socket::SSL>.

Exceptions:

An exception is thrown.

=head2 recvfrom

C<method recvfrom : int ($buffer : mutable string, $length : int, $flags : int, $from_ref : Sys::Socket::Sockaddr[], $offset : int = 0);>

This method is not supported in L<IO::Socket::SSL|SPVM::IO::Socket::SSL>.

Exceptions:

An exception is thrown.

=head1 FAQ

=head2 How to customize L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object?

Sets L</"SSL_startHandshake"> option to 0, gets a L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object by L</"ssl_ctx"> getter, customizes it, and calls L</"connect_SSL"> method in a client or calls L</"accept_SSL"> method.

Client:

  use Net::SSLeay::Constant as SSL;
  
  my $host = "www.google.com";
  my $port = 443;
  my $socket = IO::Socket::SSL->new({PeerAddr => $host, PeerPort => $port, SSL_startHandshake => 0});
  
  my $ssl_ctx = $socket->ssl_ctx;
  
  $ssl_ctx->set_min_proto_version(SSL->TLS1_1_VERSION);
  
  $socket->connect_SSL;
  
  my $ssl = $socket->ssl;

Server:

  use Net::SSLeay::Constant as SSL;
  
  my $host = "www.google.com";
  my $port = 443;
  my $socket = IO::Socket::SSL->new({Listen => 1, SSL_startHandshake => 0});
  
  my $ssl_ctx = $socket->ssl_ctx;
  
  $ssl_ctx->set_min_proto_version(SSL->TLS1_1_VERSION);
  
  my $accepted_socket = $socket->accept;
  
  $accepted_socket->accept_SSL;

=head2 How to create L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> objects for C<SSL_ca> option from the return value of L<Mozilla::CA#SSL_ca|SPVM::Mozilla::CA/"SSL_ca"> method?

  use Mozilla::CA;
  use Net::SSLeay::BIO;
  use Net::SSLeay::PEM;
  use List;
  
  my $ca = Mozilla::CA->SSL_ca;
  
  my $bio = Net::SSLeay::BIO->new;
  
  $bio->write($ca);
  
  my $x509s_list = List->new(new Net::SSLeay::X509[0]);
  while (1) {
    my $x509 = (Net::SSLeay::X509)undef;
    
    eval { $x509 = Net::SSLeay::PEM->read_bio_X509($bio); }
    
    if ($@) {
      if (eval_error_id isa_error Net::SSLeay::Error::PEM_R_NO_START_LINE) {
        last;
      }
      else {
        die $@;
      }
    }
    
    $x509s_list->push($x509);
  }
  
  my $x509s = (Net::SSLeay::X509[])$x509s_list->to_array;
  
  my $SSL_ca_option = $x509x;

=head1 See Also

=over 2

=item * L<IO::Socket::IP|SPVM::IO::Socket::IP>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Repository

L<SPVM::IO::Socket::SSL - Github|https://github.com/yuki-kimoto/SPVM-IO-Socket-SSL>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

