package SPVM::IO::Socket::SSL;

our $VERSION = "0.004";

1;

=head1 Name

SPVM::IO::Socket::SSL - Sockets for SSL.

=head1 Description

B<This class is highly experimental and not yet implemented completly and not tested well and not yet documented.>

IO::Socket::SSL class in L<SPVM> has methods for SSL sockets.

=head1 Usage

  use IO::Socket::SSL;

  # Client
  my $client_socket = IO::Socket::SSL->new({
    PeerAddr => "www.google.com:443"
  });
  
  # Server
  my $server_socket = IO::Socket::SSL->new({
    Listen => 10,
  });
  $server_socket->accept;
  
=head1 Super Class

L<IO::Socket::IP|SPVM::IO::Socket::IP>

=head1 Fields

=head2 ssl

C<has ssl : ro L<Net::SSLeay|SPVM::Net::SSLeay>;>

A L<Net::SSLeay|SPVM::Net::SSLeay> object.

=head2 SSL_version

C<has SSL_version : string;>

=head2 SSL_verify_mode

C<has SSL_verify_mode : int;>

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

=item * SSL_version : string

=item * SSL_verify_mode : Int

=item * SSL_hostname : string

=item * SSL_cipher_list : string

=item * SSL_ciphersuites : string

=item * SSL_check_crl : Int

=item * SSL_crl_file : string

=item * SSL_server : Int

=item * SSL_alpn_protocols : string[]

=item * SSL_startHandshake : Int = 1

=item * SSL_honor_cipher_order : Int = 0;

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

=head2 close

C<method close : void ();>

=head2 stat

C<method stat : L<Sys::IO::Stat|SPVM::Sys::IO::Stat> ();

This method is not allowed in IO::Scoekt::SSL.

Exceptions:

An exception is thrown.

=head2 send

C<method send : int ($buffer : string, $flags : int = 0, $length : int = -1, $offset : int = 0);>

This method is not allowed in IO::Scoekt::SSL.

Exceptions:

An exception is thrown.

=head2 sendto

C<method sendto : int ($buffer : string, $flags : int, $to : Sys::Socket::Sockaddr, $length : int = -1, $offset : int = 0);>

This method is not allowed in IO::Scoekt::SSL.

Exceptions:

An exception is thrown.

=head2 recv

C<method recv : int ($buffer : mutable string, $length : int = -1, $flags : int = 0, $offset : int = 0);>

This method is not allowed in IO::Scoekt::SSL.

Exceptions:

An exception is thrown.

=head2 recvfrom

C<method recvfrom : int ($buffer : mutable string, $length : int, $flags : int, $from_ref : Sys::Socket::Sockaddr[], $offset : int = 0);>

This method is not allowed in IO::Scoekt::SSL.

Exceptions:

An exception is thrown.

=head2 dump_peer_certificate

C<method dump_peer_certificate : string ();>

Calls L<Net::SSLeay#P_dump_peer_certificate|SPVM::Net::SSLeay/"P_dump_peer_certificate"> method given the value of L</"ssl"> field, and returns its return value.

Exceptions:

Exceptions thrown by L<Net::SSLeay#P_dump_peer_certificate|SPVM::Net::SSLeay/"P_dump_peer_certificate"> method could be thrown.

=head2 next_proto_negotiated

C<method next_proto_negotiated : string ();>

Calls L<Net::SSLeay#get0_next_proto_negotiated|SPVM::Net::SSLeay/"get0_next_proto_negotiated"> method given appropriate arguments, converts the value of output argument to a string of appropriate length, and retunrs it.

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

=head2 get_fingerprint_bin

C<method get_fingerprint_bin : string ($algo : string = undef, $cert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> = undef, $key_only : int = 0);>

Returns the same output of Perl's L<IO::Socket::SSL|/"get_fingerprint_bin"> method.

=head2 get_fingerprint

C<method get_fingerprint : string ($algo : string = undef, $cert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509> = undef, $key_only : int = 0);>

Returns the same output of Perl's L<IO::Socket::SSL|/"get_fingerprint"> method.

=head1 FAQ

=head2 How to create a Net::SSLeay::X509 object for SSL_ca option from the return value of Mozilla::CA#SSL_ca method.
  
  use Mozilla::CA;
  use Net::SSLeay::BIO;
  use Net::SSLeay::PEM;
  
  my $ca = Mozilla::CA->SSL_ca;
  
  my $bio = Net::SSLeay::BIO->new;
  
  $bio->write($ca);
  
  my $x509 = Net::SSLeay::PEM->read_bio_X509($bio);
  
  my $SSL_ca = $x509;
  
=head1 Repository

L<SPVM::IO::Socket::SSL - Github|https://github.com/yuki-kimoto/SPVM-IO-Socket-SSL>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

