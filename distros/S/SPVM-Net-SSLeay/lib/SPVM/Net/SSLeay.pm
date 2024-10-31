package SPVM::Net::SSLeay;

our $VERSION = "0.004";

1;

=head1 Name

SPVM::Net::SSLeay - SPVM bindings for OpenSSL

=head1 Description

The Net::SSLeay class of L<SPVM> has methods to call OpenSSL functions.

=head1 Usage

  use Net::SSLeay;

=head1 Fields

=head2 operation_error

  has operation_error : ro int;

=head2 error

  has error : ro long;

=head1 Class Methods

=head2 new

  static method new : Net::SSLeay ($ssl_ctx : Net::SSLeay::SSL_CTX);

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

=head2 set_fd

  method set_fd : int ($fd : int);

=head2 connect

  method connect : int ();

=head2 accept

  method accept : int ();

=head2 shutdown

  method shutdown : int ();

=head2 set_tlsext_host_name

  method set_tlsext_host_name : int ($name : string);

=head2 read

  method read : int ($buf : mutable string, $num : int = -1, $offset : int = 0);

=head2 peek

  method peek : int ($buf : mutable string, $num : int = -1, $offset : int = 0);

=head2 write

  method write : int ($buf : string, $num : int = -1, $offset : int = 0);

=head1 Examples

HTTPS Client:

  # Socket
  my $host = "www.google.com";
  my $port = 443;
  my $socket = IO::Socket::INET->new({PeerAddr => $host, PeerPort => $port});
  
  my $ssl_method = Net::SSLeay::SSL_METHOD->SSLv23_client_method;
  
  my $ssl_ctx = Net::SSLeay::SSL_CTX->new($ssl_method);
  
  $ssl_ctx->set_verify(SSL->SSL_VERIFY_PEER);
  
  $ssl_ctx->set_default_verify_paths;
  
  my $verify_param = $ssl_ctx->get0_param;
  
  $verify_param->set_hostflags(SSL->X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
  
  $verify_param->set1_host($host);
  
  my $ssl = Net::SSLeay->new($ssl_ctx);
  
  my $socket_fileno = $socket->fileno;
  
  $ssl->set_fd($socket_fileno);
  
  $ssl->set_tlsext_host_name($host);
  
  $ssl->connect;
  
  my $send_buffer = "GET / HTTP/1.0\r\n\r\n";
  $ssl->write($send_buffer);
  
  my $buffer = StringBuffer->new;
  
  my $recv_buffer = (mutable string)new_string_len 100;
  while (1) {
    my $recv_length = $ssl->read($recv_buffer);
    
    if ($recv_length > 0) {
      $buffer->push($recv_buffer, 0, $recv_length);
      # print $recv_buffer;
    }
    
    if ($recv_length < 0) {
      die "Read error";
    }
    
    if ($recv_length < length $recv_buffer) {
      last;
    }
  }
  
  my $shutdown_ret = $ssl->shutdown;
  
  if ($shutdown_ret == 0) {
    while (1) {
      my $recv_buffer = (mutable string)new_string_len 100;
      my $read_length = $ssl->read($recv_buffer);
      if ($read_length <= 0) {
        last;
      }
    }
  }
  
  $socket->close;

=head1 Modules

=over 2

=item * L<SPVM::SSLeay::Constant>

=item * L<SPVM::SSLeay::ERR>

=item * L<SPVM::SSLeay::SSL_CTX>

=item * L<SPVM::SSLeay::SSL_METHOD>

=item * L<SPVM::SSLeay::X509_VERIFY_PARAM>

=back

=head1 Repository

L<SPVM::Net::SSLeay - Github|https://github.com/yuki-kimoto/SPVM-Net-SSLeay>

=head1 Author

Yuki Kimoto<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

