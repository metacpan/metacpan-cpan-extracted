package SPVM::IO::Socket::SSL;

our $VERSION = "0.002";

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

C<has ssl : L<Net::SSLeay|SPVM::Net::SSLeay>;>

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

=head2 SSL_passwd_cb

C<has SSL_passwd_cb : L<Net::SSLeay::Callback::PemPasswd|SPVM::Net::SSLeay::Callback::PemPasswd>;>

=head2 SSL_server

C<has SSL_server : int;>

=head2 SSL_server_specified

C<has SSL_server_specified : int;>

=head2 SSL_npn_protocols

C<has SSL_npn_protocols : string[];>

=head2 SSL_alpn_protocols

C<has SSL_alpn_protocols : string[];>

=head2 SSL_ticket_keycb

C<has SSL_ticket_keycb : L<Net::SSLeay::Callback::TlsextTicketKey|SPVM::Net::SSLeay::Callback::TlsextTicketKey>;>
  
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

=item * SSL_check_crl : int

=item * SSL_crl_file : string

=item * SSL_passwd_cb : L<Net::SSLeay::Callback::PemPasswd|SPVM::Net::SSLeay::Callback::PemPasswd>

=item * SSL_server : int

=item * SSL_npn_protocols : string[]

=item * SSL_alpn_protocols : string[]

=item * SSL_ticket_keycb : L<Net::SSLeay::Callback::TlsextTicketKey|SPVM::Net::SSLeay::Callback::TlsextTicketKey>

=back

=head2 configure

C<protected method configure : void ();>

=head2 configure_SSL

C<protected method configure_SSL : void ();>

=head2 connect_SSL

C<protected method connect_SSL : void ();>

=head2 accept_SSL

C<private method accept_SSL : void ();>

=head2 accept

C<method accept : IO::Socket::SSL ($peer_ref : Sys::Socket::Sockaddr[] = undef);>

=head2 read

C<method read : int ($buffer : mutable string, $length : int = -1, $offset : int = 0);>

=head2 write

C<method write : int ($buffer : string, $length : int = -1, $offset : int = 0);>

=head2 close

C<method close : void ();>

=head2 stat

C<method stat : Sys::IO::Stat ();> die "stat method is not allowed in IO::Scoekt::SSL."; }

=head2 send

C<method send : int ($buffer : string, $flags : int = 0, $length : int = -1, $offset : int = 0);>

=head2 sendto

C<method sendto : int ($buffer : string, $flags : int, $to : Sys::Socket::Sockaddr, $length : int = -1, $offset : int = 0);>

=head2 recv

C<method recv : int ($buffer : mutable string, $length : int = -1, $flags : int = 0, $offset : int = 0);>

=head2 recvfrom

C<method recvfrom : int ($buffer : mutable string, $length : int, $flags : int, $from_ref : Sys::Socket::Sockaddr[], $offset : int = 0);>

=head1 Repository

L<SPVM::IO::Socket::SSL - Github|https://github.com/yuki-kimoto/SPVM-IO-Socket-SSL>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

