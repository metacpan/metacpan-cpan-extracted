package SPVM::Sys::Socket;

1;

=head1 Name

SPVM::Sys::Socket - System Calls for Sockets

=head1 Description

Sys::Socket class in L<SPVM> has methods to call system calls for sockets.

=head1 Usage
  
  use Sys::Socket;
  use Sys::Socket::Constant as SOCKET;
  
  my $socket_fd = Sys::Socket->socket(SOCKET->AF_INET, SOCKET->SOCK_STREAM, 0);

=head1 Class Methods

=head2 htonl

C<static method htonl : int ($hostlong : int);>

Calls the L<htonl|https://linux.die.net/man/3/htonl> function and returns its return value.

=head2 htons

C<static method htons : short ($hostshort : short);>

Calls the L<htons|https://linux.die.net/man/3/htons> function and returns its return value.

=head2 ntohl

C<static method ntohl : int ($netlong : int);>

Calls the L<ntohl|https://linux.die.net/man/3/ntohl> function and returns its return value.

=head2 ntohs

C<static method ntohs : short ($netshort : short);>

Calls the L<ntohs|https://linux.die.net/man/3/ntohs> function and returns its return value.

=head2 inet_aton

C<static method inet_aton : int ($cp : string, $inp : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr>);>

Calls the L<inet_aton|https://linux.die.net/man/3/inet_aton> function and returns its return value.

Excetpions:

$cp must be defined. Otherwise an excetpion is thrown.

$inp must be defined. Otherwise an excetpion is thrown.

If the got address is not a valid network, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Sys::Socket::Error::InetInvalidNetworkAddress> class.

If the inet_aton function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 inet_ntoa

C<static method inet_ntoa : string ($in : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr>);>

Calls the L<inet_ntoa|https://linux.die.net/man/3/inet_ntoa> function and returns its return value.

Excetpions:

$in address must be defined. Otherwise an excetpion is thrown.

If the inet_ntoa function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Sys::Socket::Error::InetInvalidNetworkAddress> class.

=head2 inet_pton

C<static method inet_pton : int ($af : int, $src : string, $dst : L<Sys::Socket::In_addr_base|SPVM::Sys::Socket::In_addr_base>);>

Calls the L<inet_pton|https://linux.die.net/man/3/inet_pton> function and returns its return value.

See L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant> about constant values given to $af.

Exceptions:

$af must be AF_INET or AF_INET6. Otherwise an excetpion is thrown.

$dst must be defined. Otherwise an excetpion is thrown.

If $af must be AF_INET, $dst must be the Sys::Socket::In_addr class. Otherwise an excetpion is thrown.

If $af must be AF_INET6, $dst must be the Sys::Socket::In6_addr class. Otherwise an excetpion is thrown.

If the type of $dst is invalid, otherwise an excetpion is thrown.

If the got address is not a valid network, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Sys::Socket::Error::InetInvalidNetworkAddress> class.

If the inet_pton function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 inet_ntop

C<static method inet_ntop : mutable string ($af : int, $src : L<Sys::Socket::In_addr_base|SPVM::Sys::Socket::In_addr_base>, $dst : mutable string, $size : int);>

Calls the L<inet_ntop|https://linux.die.net/man/3/inet_ntop> function and returns its return value.

See L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant> about constant values given to $af.

Excetpions:

$af must be AF_INET or AF_INET6. Otherwise an excetpion is thrown.

$src must be defined. Otherwise an excetpion is thrown.

$dst must be defined. Otherwise an excetpion is thrown.

If the inet_ntop function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 socket

C<static method socket : int ($domain : int, $type : int, $protocol : int);>

Calls the L<socket|https://linux.die.net/man/2/socket> function and returns its return value.

See L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant> about constant values given to $domain, $type, and $protocal.

Excetpions:

If the socket function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 connect

C<static method connect : int ($sockfd : int, $addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>, $addrlen : int);>

Calls the L<connect|https://linux.die.net/man/2/connect> function and returns its return value.

Excetpions:

$addr must be defined. Otherwise an excetpion is thrown.

If the connect function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 bind

C<static method bind : int ($sockfd : int, $addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>, $addrlen : int);>

Calls the L<bind|https://linux.die.net/man/2/bind> function and returns its return value.

Excetpions:

$addr must be defined. Otherwise an excetpion is thrown.

If the bind function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 accept

C<static method accept : int ($sockfd : int, $addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>, $addrlen_ref : int*);>

Calls the L<accept|https://linux.die.net/man/2/accept> function and returns its return value.

Exceptions:

$addr must be defined. Otherwise an excetpion is thrown.

If the accept function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 listen

C<static method listen : int ($sockfd : int, $backlog : int);>

Calls the L<listen|https://linux.die.net/man/2/listen> function and returns its return value.

Excetpions:

If the listen function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 shutdown

C<static method shutdown : int ($sockfd : int, $how : int);>

Calls the L<shutdown|https://linux.die.net/man/2/shutdown> function and returns its return value.

See L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant> about constant values given to $how.

Excetpions:

If the shutdown function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 closesocket

C<static method closesocket : int ($fd : int);>

Calls the L<closesocket|https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-closesocket> function and returns its return value.

Excetpions:

If the closesocket function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 close

C<static method close : int ($fd : int);>

Calls the L</"closesocket"> method in Windows.

Calls L<the#close|SPVM::the/"close"> method Sys::IO class in other OSs.

=head2 recv

C<static method recv : int ($sockfd : int, $buf : mutable string, $len : int, $flags : int, $buf_offset : int = 0);>

Calls the L<recv|https://linux.die.net/man/2/recv> function and returns its return value.

Excetpions:

$buf must be defined. Otherwise an excetpion is thrown.

$len must be less than the length of $buf - $buf_offset. Otherwise an excetpion is thrown.

If the recv function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 recvfrom

C<static method recvfrom : int ($sockfd : int, $buf : mutable string, $len : int, $flags : int, $src_addr : Sys::Socket::Sockaddr, $addrlen_ref : int*, $buf_offset : int = 0);>

Calls the L<recvfromv|https://linux.die.net/man/2/recvfrom> function and returns its return value.

Excetpions:

$buf must be defined. Otherwise an excetpion is thrown.

$len must be less than the length of $buf - $buf_offset. Otherwise an excetpion is thrown.

If the recv function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 send

C<static method send : int ($sockfd : int, $buf : string, $len : int, $flags : int, $buf_offset : int = 0);>

Calls the L<send|https://linux.die.net/man/2/send> function and returns its return value.

Excetpions:

$buf must be defined. Otherwise an excetpion is thrown.

$len must be less than the length of $buf - $buf_offset. Otherwise an excetpion is thrown.

If the send function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 sendto

C<static method sendto : int ($sockfd : int, $buf : string, $len : int, $flags : int, $addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>, $addrlen : int, $buf_offset : int = 0);>

Calls the L<sendto|https://linux.die.net/man/2/sendto> function and returns its return value.

Excetpions:

$buf must be defined. Otherwise an excetpion is thrown.

$len must be less than the length of $buf - $buf_offset. Otherwise an excetpion is thrown.

If the send function failed, an excetpion is thrownn with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 getpeername

C<static method getpeername : int ($sockfd : int, $addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>, $addrlen_ref : int*);>

Calls the L<getpeername|https://linux.die.net/man/2/getpeername> function and returns its return value.

Exceptions:

$addr must be defined. Otherwise an exception is thrown.

If the getpeername function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

Excetpions:

=head2 getsockname

C<static method getsockname : int ($sockfd : int, $addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>, $addrlen_ref : int*);>

Calls the L<getsockname|https://linux.die.net/man/2/getsockname> function and returns its return value.

Excetpions:

$addr must be defined. Otherwise an exception is thrown.

If the getsockname function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

Excetpions:

=head2 getsockopt

C<static method getsockopt : int ($sockfd : int, $level : int, $optname : int, $optval : mutable string, $optlen_ref : int*);>

Calls the L<getsockopt|https://linux.die.net/man/2/getsockopt> function and returns its return value.

See L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant> about constant values given to $level and $optname.

Exceptions:

$optval must be defined. Otherwise an exception is thrown.

The referred value of $optlen_ref must be greater than or equal to 0. Otherwise an exception is thrown.

The referred value of $optlen_ref must be less than or equal to the length of $optval. Otherwise an exception is thrown.

If the getsockopt function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 setsockopt

C<static method setsockopt : int ($sockfd : int, $level : int, $optname : int, $optval : string, $optlen : int);>

Calls the L<setsockopt|https://linux.die.net/man/2/setsockopt> function and returns its return value.

See L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant> about constant values given to $level and $optname.

Exceptions:

$optval must be defined. Otherwise an exception is thrown.

$optlen must be greater than or equal to 0. Otherwise an exception is thrown.

$optlen must be less than or equal to the length of $optval. Otherwise an exception is thrown.

If the setsockopt function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 socketpair

C<static method socketpair : int ($domain : int, $type : int, $protocol : int, $sv : int[]);>

Calls the L<socketpair|https://linux.die.net/man/2/socketpair> function and returns its return value.

See L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant> about constant values given to $domain, $type, and $protocol.

Exceptions:

$sv must be defined. Otherwise an exception is thrown.

The length of $sv must be greater than or equal to 2. Otherwise an exception is thrown.

If the socketpair function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 getaddrinfo

C<static method getaddrinfo : int ($node : string, $service : string, $hints : L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo>, $res_ref : L<Sys::Socket::AddrinfoLinkedList|SPVM::Sys::Socket::AddrinfoLinkedList>[]);>

Calls the L<getaddrinfo|https://linux.die.net/man/3/getaddrinfo> function and returns its return value.

Exceptions:

$res_array must be defined. Otherwise an exception is thrown.

The length of $res_array must be equal to 1.

If the getnameinfo function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 getnameinfo

C<static method getnameinfo : int ($sa : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>, $salen : int, $host : mutable string, $hostlen : int, $serv : mutable string, $servlen : int, $flags : int);>

Calls the L<getnameinfo|https://linux.die.net/man/3/getaddrinfo> function and returns its return value.

Excetpions:

$sa must be defined. Otherwise an exception is thrown.

If the getnameinfo function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 gai_strerror

C<static method gai_strerror : string($errcode : int);>

Calls the L<gai_strerror|https://linux.die.net/man/3/gai_strerror> function and returns its return value.

Excepsions:

If the gai_strerror function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 sockatmark

C<static method sockatmark : int ($sockfd : int);>

Calls the L<sockatmark|https://linux.die.net/man/3/sockatmark> function and returns its return value.

Excepsions:

If the sockatmark function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

