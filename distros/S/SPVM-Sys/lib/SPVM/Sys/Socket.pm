package SPVM::Sys::Socket;

1;

=head1 Name

SPVM::Sys::Socket - Socket System Call

=head1 Usage
  
  use Sys::Socket;
  use Sys::Socket::Constant as Sock;
  my $socket = Sys::Socket->socket(Sock->AF_INET, Sock->SOCK_STREAM, 0);

=head1 Description

C<Sys::Socket> is the class for system calls of socket.

=head1 Class Methods

=head2 htonl

  static method htonl : int ($hostlong : int);

The htonl() function converts the unsigned integer hostlong from host byte order to network byte order.

See the detail of the L<htonl|https://linux.die.net/man/3/htonl> function in the case of Linux.

=head2 htons

  static method htons : short ($hostshort : short);

The htons() function converts the unsigned short integer hostshort from host byte order to network byte order.

See the detail of the L<htons|https://linux.die.net/man/3/htons> function in the case of Linux.

=head2 ntohl

  static method ntohl : int ($netlong : int);

The ntohl() function converts the unsigned integer netlong from network byte order to host byte order.

See the detail of the L<ntohl|https://linux.die.net/man/3/ntohl> function in the case of Linux.

=head2 ntohs

  static method ntohs : short ($netshort : short);

The ntohs() function converts the unsigned short integer netshort from network byte order to host byte order.

See the detail of the L<ntohs|https://linux.die.net/man/3/ntohs> function in the case of Linux.

=head2 inet_aton

  static method inet_aton : int ($cp : string, $inp : Sys::Socket::In_addr);

inet_aton() converts the Internet host address cp from the IPv4 numbers-and-dots notation into binary form (in network byte order) and stores it in the structure that inp points to. inet_aton() returns nonzero if the address is valid, zero if not. The address supplied in cp can have one of the following forms:

See the detail of the L<inet_aton|https://linux.die.net/man/3/inet_aton> function in the case of Linux.

The input address(inp) is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

The input address(cp) must be defined. Otherwise an exception will be thrown.

The output address(inp) must be defined. Otherwise an exception will be thrown.

=head2 inet_ntoa

  static method inet_ntoa : string ($in : Sys::Socket::In_addr);

The inet_ntoa() function converts the Internet host address in, given in network byte order, to a string in IPv4 dotted-decimal notation. The string is returned in a statically allocated buffer, which subsequent calls will overwrite.

See the detail of the L<inet_ntoa|https://linux.die.net/man/3/inet_ntoa> function in the case of Linux.

The input address(in) is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

The input address must be defined. Otherwise an exception will be thrown.

=head2 inet_pton

  static method inet_pton : int ($af : int, $src : string, $dst : object of Sys::Socket::In_addr|Sys::Socket::In6_addr);

This function converts the character string src into a network address structure in the af address family, then copies the network address structure to dst. The af argument must be either AF_INET or AF_INET6.

See the detail of the L<inet_pton|https://linux.die.net/man/3/inet_pton> function in the case of Linux.

The output address(dst) is assumed to be L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> or L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> corresponding to the address family(af).

The input address(src) must be defined. Otherwise an exception will be thrown.

The output address(dst) must be defined. Otherwise an exception will be thrown.

=head2 inet_ntop

  static method inet_ntop : mutable string ($af : int, $src : object of Sys::Socket::In_addr|Sys::Socket::In6_addr, $dst : mutable string, $size : int);

This function converts the network address structure src in the af address family into a character string. The resulting string is copied to the buffer pointed to by dst, which must be a non-NULL pointer. The caller specifies the number of bytes available in this buffer in the argument size.

See the detail of the L<inet_ntop|https://linux.die.net/man/3/inet_ntop> function in the case of Linux.

The input address(src) is assumed to be L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> or L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> corresponding to the address family(af).

The input address(src) must be defined. Otherwise an exception will be thrown.

The output address(dst) must be defined. Otherwise an exception will be thrown.

=head2 socket

  static method socket : int ($domain : int, $type : int, $protocol : int);

socket() creates an endpoint for communication and returns a descriptor.
The domain argument specifies a communication domain; this selects the protocol family which will be used for communication. These families are defined in <sys/socket.h>. The currently understood formats include:

See the detail of the L<socket|https://linux.die.net/man/2/socket> function in the case of Linux.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 connect

  static method connect : int ($sockfd : int, $addr : Sys::Socket::Sockaddr, $addrlen : int);

The connect() system call connects the socket referred to by the file descriptor sockfd to the address specified by addr. The addrlen argument specifies the size of addr. The format of the address in addr is determined by the address space of the socket sockfd; see socket(2) for further details.

See the detail of the L<connect|https://linux.die.net/man/2/connect> function in the case of Linux.

The address(C<$addr>) is a L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> object.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 bind

  static method bind : int ($sockfd : int, $addr : Sys::Socket::Sockaddr, $addrlen : int);

When a socket is created with socket(2), it exists in a name space (address family) but has no address assigned to it. bind() assigns the address specified by addr to the socket referred to by the file descriptor sockfd. addrlen specifies the size, in bytes, of the address structure pointed to by addr. Traditionally, this operation is called "assigning a name to a socket".

See the detail of the L<bind|https://linux.die.net/man/2/bind> function in the case of Linux.

The address(C<$addr>) is a L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> object.

The address must be defined. Otherwise an exception will be thrown.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 accept

  static method accept : int ($sockfd : int, $addr : Sys::Socket::Sockaddr, $addrlen_ref : int*);

The accept() system call is used with connection-based socket types (SOCK_STREAM, SOCK_SEQPACKET). It extracts the first connection request on the queue of pending connections for the listening socket, sockfd, creates a new connected socket, and returns a new file descriptor referring to that socket. The newly created socket is not in the listening state. The original socket sockfd is unaffected by this call.

See the detail of the L<accept|https://linux.die.net/man/2/accept> function in the case of Linux.

The address(C<$addr>) is a L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> object.

The address must be defined. Otherwise an exception will be thrown.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 listen

  static method listen : int ($sockfd : int, $backlog : int);

listen() marks the socket referred to by sockfd as a passive socket, that is, as a socket that will be used to accept incoming connection requests using accept(2).

See the detail of the L<listen|https://linux.die.net/man/2/listen> function in the case of Linux.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 shutdown

  static method shutdown : int ($sockfd : int, $how : int);

The shutdown() call causes all or part of a full-duplex connection on the socket associated with sockfd to be shut down. If how is SHUT_RD, further receptions will be disallowed. If how is SHUT_WR, further transmissions will be disallowed. If how is SHUT_RDWR, further receptions and transmissions will be disallowed.

See the detail of the L<shutdown|https://linux.die.net/man/2/shutdown> function in the case of Linux.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 recv

  static method recv : int ($sockfd : int, $buf : mutable string, $len : int, $flags : int);

The recv() call is normally used only on a connected socket (see connect(2)) and is identical to recvfrom() with a NULL src_addr argument.

See the detail of the L<recv|https://linux.die.net/man/2/recv> function in the case of Linux.

The buffer(C<$buf> must be defined. Otherwise an exception will be thrown.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 send

  static method send : int ($sockfd : int, $buf : string, $len : int, $flags : int);

The send() call may be used only when the socket is in a connected state (so that the intended recipient is known). The only difference between send() and write(2) is the presence of flags. With a zero flags argument, send() is equivalent to write(2). Also, the following call

The buffer(C<$buf> must be defined. Otherwise an exception will be thrown.

See the detail of the L<send|https://linux.die.net/man/2/send> function in the case of Linux.

=head2 getpeername

  static method getpeername : int ($sockfd : int, $addr : Sys::Socket::Sockaddr, $addrlen_ref : int*);

getpeername() returns the address of the peer connected to the socket sockfd, in the buffer pointed to by addr. The addrlen argument should be initialized to indicate the amount of space pointed to by addr. On return it contains the actual size of the name returned (in bytes). The name is truncated if the buffer provided is too small.

See the detail of the L<getpeername|https://linux.die.net/man/2/getpeername> function in the case of Linux.

The address(C<$addr>) is a L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> object.

The address must be defined. Otherwise an exception will be thrown.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 getsockname

  static method getsockname : int ($sockfd : int, $addr : Sys::Socket::Sockaddr, $addrlen_ref : int*);

getsockname() returns the current address to which the socket sockfd is bound, in the buffer pointed to by addr. The addrlen argument should be initialized to indicate the amount of space (in bytes) pointed to by addr. On return it contains the actual size of the socket address.

See the detail of the L<getsockname|https://linux.die.net/man/2/getsockname> function in the case of Linux.

The address(C<$addr>) is a L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> object.

The address must be defined. Otherwise an exception will be thrown.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 socketpair

  static method socketpair : int ($domain : int, $type : int, $protocol : int, $sv : int[]);

The socketpair() call creates an unnamed pair of connected sockets in the specified domain, of the specified type, and using the optionally specified protocol. For further details of these arguments, see socket(2).

See the detail of the L<socketpair|https://linux.die.net/man/2/socketpair> function in the case of Linux.

The output of the socket pair(sv) must be defined. Otherwise an exception will be thrown.

The length of the output of the socket pair(sv) must be greater than or equal to 2. Otherwise an exception will be thrown.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 setsockopt

  static method setsockopt : int ($sockfd : int, $level : int, $optname : int, $optval : string, $optlen : int);

getsockopt() and setsockopt() manipulate options for the socket referred to by the file descriptor sockfd. Options may exist at multiple protocol levels; they are always present at the uppermost socket level.

See the detail of the L<setsockopt|https://linux.die.net/man/2/setsockopt> function in the case of Linux.

The option value must be defined. Otherwise an exception will be thrown.

The option length must be greater than or equal to 0. Otherwise an exception will be thrown.

The length of the option value must be less than or equal to the option length. Otherwise an exception will be thrown.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 setsockopt_int

  static method setsockopt_int : int ($sockfd : int, $level : int, $optname : int, $optval : int);

The same as L</"setsockopt">, but the option value can be specifed by the C<int> type.

=head2 getsockopt

  static method getsockopt : int ($sockfd : int, $level : int, $optname : int, $optval : mutable string, $optlen_ref : int*);

getsockopt() and setsockopt() manipulate options for the socket referred to by the file descriptor sockfd. Options may exist at multiple protocol levels; they are always present at the uppermost socket level.

See the detail of the L<getsockopt|https://linux.die.net/man/2/getsockopt> function in the case of Linux.

The option value must be defined. Otherwise an exception will be thrown.

The option length must be greater than or equal to 0. Otherwise an exception will be thrown.

The length of the option value must be less than or equal to the option length. Otherwise an exception will be thrown.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 getsockopt_int

  static method getsockopt_int : int ($sockfd : int, $level : int, $optname : int, $optval_ref : int*);

The same as L</"getsockopt">, but the option value can be specifed by the C<int> type.

=head2 ioctlsocket

  static method ioctlsocket : int ($s : int, $cmd : int, $argp : int*);

The ioctlsocket function controls the I/O mode of a socket.

See the detail of the L<ioctlsocket|https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-ioctlsocket> function in the case of Windows.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 closesocket

  static method closesocket : int ($s : int);

The closesocket function closes an existing socket.

See the detail of the L<closesocket|https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-closesocket> function in the case of Windows.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 WSAPoll

  static method WSAPoll : int ($fds : Sys::IO::PollfdArray, $nfds : int, $timeout : int);

The WSAPoll function determines status of one or more sockets.

See the detail of the L<WSAPoll|https://docs.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsapoll> function in the case of Windows.

The file descriptors(fds) is a L<Sys::IO::PollfdArray> object.

If the system call failed, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 getaddrinfo_raw

  static method getaddrinfo_raw : int ($node : string, $service : string,
                $hints : Sys::Socket::Addrinfo,
                $res : Sys::Socket::Addrinfo[]);

Same as the L</"getaddrinfo"> method, but doesn't throw exceptions related to system errors.

=head2 getaddrinfo

  static method getaddrinfo : int ($node : string, $service : string,
                $hints : Sys::Socket::Addrinfo,
                $res : Sys::Socket::Addrinfo[]);

Given node and service, which identify an Internet host and a service, getaddrinfo() returns one or more addrinfo structures, each of which contains an Internet address that can be specified in a call to bind(2) or connect(2). The getaddrinfo() function combines the functionality provided by the gethostbyname(3) and getservbyname(3) functions into a single interface, but unlike the latter functions, getaddrinfo() is reentrant and allows programs to eliminate IPv4-versus-IPv6 dependencies.

See the detail of the L<getaddrinfo|https://linux.die.net/man/3/getaddrinfo> function in the case of Linux.

The hints is a L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo> object.

The response(res) is an array of the L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo>.

The response must be defined. Otherwise an exception will be thrown.

The length of the array of the response must be greater than or equal to 1. Otherwise an exception will be thrown.

If a system error occur, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 getnameinfo_raw

  static method getnameinfo_raw : int ($sa : Sys::Socket::Sockaddr, $salen : int,
                $host : mutable string, $hostlen : int,
                $serv : mutable string, $servlen : int, $flags : int);

Same as the L</"getnameinfo"> method, but doesn't throw exceptions related to system errors.

=head2 getnameinfo

  static method getnameinfo : int ($sa : Sys::Socket::Sockaddr, $salen : int,
                $host : mutable string, $hostlen : int,
                $serv : mutable string, $servlen : int, $flags : int);

The getnameinfo() function is the inverse of getaddrinfo(3): it converts a socket address to a corresponding host and service, in a protocol-independent manner. It combines the functionality of gethostbyaddr(3) and getservbyport(3), but unlike those functions, getnameinfo() is reentrant and allows programs to eliminate IPv4-versus-IPv6 dependencies.

See the detail of the L<getnameinfo|https://linux.die.net/man/3/getaddrinfo> function in the case of Linux.

The socket address(sa) is a L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo> object.

If a system error occur, an exception will be thrown with the error code set to the class id of the L<Error::System> class.

=head2 gai_strerror

  static method gai_strerror : string($errcode : int);

The gai_strerror() function translates these error codes to a human readable string, suitable for error reporting.

See the detail of the L<getnameinfo|https://linux.die.net/man/3/gai_strerror> function in the case of Linux.

=head2 ioctl_int

  static method ioctl_int : int ($fd : int, $request : int, $request_arg_ref : int*);

The same as L<ioctl_int in Sys::IO|SPVM::Sys::IO/"ioctl_int">, but portable in socket.

=head2 poll

  static method poll : int ($fds : Sys::IO::PollfdArray, $nfds : int, $timeout : int);

The same as L<poll in Sys::IO|SPVM::Sys::IO/"poll">, but portable in socket.

The file descriptors(fds) is a L<Sys::IO::PollfdArray> object.

=head2 close

  static method close : int ($fd : int);

The same as L<close in Sys::IO|SPVM::Sys::IO/"close">, but portable in socket.

=head2 socket_errno

  static method socket_errno : int ();

Portalbe C<errno> related to the errors of the socket.

=head2 socket_strerror

  static method socket_strerror : string ($errno : int, $length : int);

Portalbe C<strerror> related to the errors of the socket.
