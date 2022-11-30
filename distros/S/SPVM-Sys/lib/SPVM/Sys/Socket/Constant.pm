package SPVM::Sys::Socket::Constant;

1;

=head1 Name

SPVM::Sys::Socket::Constant - Socket Constant Values

=head1 Usage

  use Sys::Socket::Constant as Sock;
  
  Sock->AF_INET;
  Sock->SOL_SOCKET;
  
=head1 Description

C<Sys::Socket::Constant> is a class to provide the socket constant values.

=head1 Class Methods

=head2 AF_ALG

  static method AF_ALG : int ();

Get the constant value of C<AF_ALG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_APPLETALK

  static method AF_APPLETALK : int ();

Get the constant value of C<AF_APPLETALK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_AX25

  static method AF_AX25 : int ();

Get the constant value of C<AF_AX25>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_BLUETOOTH

  static method AF_BLUETOOTH : int ();

Get the constant value of C<AF_BLUETOOTH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_CAN

  static method AF_CAN : int ();

Get the constant value of C<AF_CAN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_DEC

  static method AF_DEC : int ();

Get the constant value of C<AF_DEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_IB

  static method AF_IB : int ();

Get the constant value of C<AF_IB>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_INET

  static method AF_INET : int ();

Get the constant value of C<AF_INET>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_INET6

  static method AF_INET6 : int ();

Get the constant value of C<AF_INET6>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_IPX

  static method AF_IPX : int ();

Get the constant value of C<AF_IPX>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_KCM

  static method AF_KCM : int ();

Get the constant value of C<AF_KCM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_KEY

  static method AF_KEY : int ();

Get the constant value of C<AF_KEY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_LLC

  static method AF_LLC : int ();

Get the constant value of C<AF_LLC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_LOCAL

  static method AF_LOCAL : int ();

Get the constant value of C<AF_LOCAL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_MPLS

  static method AF_MPLS : int ();

Get the constant value of C<AF_MPLS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_NETLINK

  static method AF_NETLINK : int ();

Get the constant value of C<AF_NETLINK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_PACKET

  static method AF_PACKET : int ();

Get the constant value of C<AF_PACKET>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_PPPOX

  static method AF_PPPOX : int ();

Get the constant value of C<AF_PPPOX>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_RDS

  static method AF_RDS : int ();

Get the constant value of C<AF_RDS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_TIPC

  static method AF_TIPC : int ();

Get the constant value of C<AF_TIPC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_UNIX

  static method AF_UNIX : int ();

Get the constant value of C<AF_UNIX>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_UNSPEC

  static method AF_UNSPEC : int ();

Get the constant value of C<AF_UNSPEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_VSOCK

  static method AF_VSOCK : int ();

Get the constant value of C<AF_VSOCK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_X25

  static method AF_X25 : int ();

Get the constant value of C<AF_X25>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AF_XDP

  static method AF_XDP : int ();

Get the constant value of C<AF_XDP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 INADDR_ANY

  static method INADDR_ANY : int ();

Get the constant value of C<INADDR_ANY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 INADDR_BROADCAST

  static method INADDR_BROADCAST : int ();

Get the constant value of C<INADDR_BROADCAST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 INADDR_LOOPBACK

  static method INADDR_LOOPBACK : int ();

Get the constant value of C<INADDR_LOOPBACK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 INADDR_NONE

  static method INADDR_NONE : int ();

Get the constant value of C<INADDR_NONE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPPROTO_IP

  static method IPPROTO_IP : int ();

Get the constant value of C<IPPROTO_IP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPPROTO_SCTP

  static method IPPROTO_SCTP : int ();

Get the constant value of C<IPPROTO_SCTP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPPROTO_TCP

  static method IPPROTO_TCP : int ();

Get the constant value of C<IPPROTO_TCP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPPROTO_UDP

  static method IPPROTO_UDP : int ();

Get the constant value of C<IPPROTO_UDP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPPROTO_UDPLITE

  static method IPPROTO_UDPLITE : int ();

Get the constant value of C<IPPROTO_UDPLITE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPTOS_LOWDELAY

  static method IPTOS_LOWDELAY : int ();

Get the constant value of C<IPTOS_LOWDELAY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPTOS_MINCOST

  static method IPTOS_MINCOST : int ();

Get the constant value of C<IPTOS_MINCOST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPTOS_RELIABILITY

  static method IPTOS_RELIABILITY : int ();

Get the constant value of C<IPTOS_RELIABILITY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPTOS_THROUGHPUT

  static method IPTOS_THROUGHPUT : int ();

Get the constant value of C<IPTOS_THROUGHPUT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_ADD_MEMBERSHIP

  static method IP_ADD_MEMBERSHIP : int ();

Get the constant value of C<IP_ADD_MEMBERSHIP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_ADD_SOURCE_MEMBERSHIP

  static method IP_ADD_SOURCE_MEMBERSHIP : int ();

Get the constant value of C<IP_ADD_SOURCE_MEMBERSHIP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_BIND_ADDRESS_NO_PORT

  static method IP_BIND_ADDRESS_NO_PORT : int ();

Get the constant value of C<IP_BIND_ADDRESS_NO_PORT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_BLOCK_SOURCE

  static method IP_BLOCK_SOURCE : int ();

Get the constant value of C<IP_BLOCK_SOURCE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_DROP_MEMBERSHIP

  static method IP_DROP_MEMBERSHIP : int ();

Get the constant value of C<IP_DROP_MEMBERSHIP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_DROP_SOURCE_MEMBERSHIP

  static method IP_DROP_SOURCE_MEMBERSHIP : int ();

Get the constant value of C<IP_DROP_SOURCE_MEMBERSHIP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_FREEBIND

  static method IP_FREEBIND : int ();

Get the constant value of C<IP_FREEBIND>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_HDRINCL

  static method IP_HDRINCL : int ();

Get the constant value of C<IP_HDRINCL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_MSFILTER

  static method IP_MSFILTER : int ();

Get the constant value of C<IP_MSFILTER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_MTU

  static method IP_MTU : int ();

Get the constant value of C<IP_MTU>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_MTU_DISCOVER

  static method IP_MTU_DISCOVER : int ();

Get the constant value of C<IP_MTU_DISCOVER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_MULTICAST_ALL

  static method IP_MULTICAST_ALL : int ();

Get the constant value of C<IP_MULTICAST_ALL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_MULTICAST_IF

  static method IP_MULTICAST_IF : int ();

Get the constant value of C<IP_MULTICAST_IF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_MULTICAST_LOOP

  static method IP_MULTICAST_LOOP : int ();

Get the constant value of C<IP_MULTICAST_LOOP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_MULTICAST_TTL

  static method IP_MULTICAST_TTL : int ();

Get the constant value of C<IP_MULTICAST_TTL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_NODEFRAG

  static method IP_NODEFRAG : int ();

Get the constant value of C<IP_NODEFRAG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_OPTION

  static method IP_OPTION : int ();

Get the constant value of C<IP_OPTION>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_OPTIONS

  static method IP_OPTIONS : int ();

Get the constant value of C<IP_OPTIONS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_ORIGDSTADDR

  static method IP_ORIGDSTADDR : int ();

Get the constant value of C<IP_ORIGDSTADDR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_PASSSEC

  static method IP_PASSSEC : int ();

Get the constant value of C<IP_PASSSEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_PKTINFO

  static method IP_PKTINFO : int ();

Get the constant value of C<IP_PKTINFO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_PMTUDISC_DO

  static method IP_PMTUDISC_DO : int ();

Get the constant value of C<IP_PMTUDISC_DO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_PMTUDISC_DONT

  static method IP_PMTUDISC_DONT : int ();

Get the constant value of C<IP_PMTUDISC_DONT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_PMTUDISC_PROBE

  static method IP_PMTUDISC_PROBE : int ();

Get the constant value of C<IP_PMTUDISC_PROBE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_PMTUDISC_WANT

  static method IP_PMTUDISC_WANT : int ();

Get the constant value of C<IP_PMTUDISC_WANT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_RCVDSTADDR

  static method IP_RCVDSTADDR : int ();

Get the constant value of C<IP_RCVDSTADDR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_RECVERR

  static method IP_RECVERR : int ();

Get the constant value of C<IP_RECVERR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_RECVIF

  static method IP_RECVIF : int ();

Get the constant value of C<IP_RECVIF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_RECVOPTS

  static method IP_RECVOPTS : int ();

Get the constant value of C<IP_RECVOPTS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_RECVORIGDSTADDR

  static method IP_RECVORIGDSTADDR : int ();

Get the constant value of C<IP_RECVORIGDSTADDR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_RECVTOS

  static method IP_RECVTOS : int ();

Get the constant value of C<IP_RECVTOS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_RECVTTL

  static method IP_RECVTTL : int ();

Get the constant value of C<IP_RECVTTL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_RETOPTS

  static method IP_RETOPTS : int ();

Get the constant value of C<IP_RETOPTS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_ROUTER_ALERT

  static method IP_ROUTER_ALERT : int ();

Get the constant value of C<IP_ROUTER_ALERT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_TOS

  static method IP_TOS : int ();

Get the constant value of C<IP_TOS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_TRANSPARENT

  static method IP_TRANSPARENT : int ();

Get the constant value of C<IP_TRANSPARENT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_TTL

  static method IP_TTL : int ();

Get the constant value of C<IP_TTL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IP_UNBLOCK_SOURCE

  static method IP_UNBLOCK_SOURCE : int ();

Get the constant value of C<IP_UNBLOCK_SOURCE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MCAST_EXCLUDE

  static method MCAST_EXCLUDE : int ();

Get the constant value of C<MCAST_EXCLUDE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MCAST_INCLUDE

  static method MCAST_INCLUDE : int ();

Get the constant value of C<MCAST_INCLUDE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_CMSG_CLOEXEC

  static method MSG_CMSG_CLOEXEC : int ();

Get the constant value of C<MSG_CMSG_CLOEXEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_CONFIRM

  static method MSG_CONFIRM : int ();

Get the constant value of C<MSG_CONFIRM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_CTRUNC

  static method MSG_CTRUNC : int ();

Get the constant value of C<MSG_CTRUNC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_DONTROUTE

  static method MSG_DONTROUTE : int ();

Get the constant value of C<MSG_DONTROUTE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_DONTWAIT

  static method MSG_DONTWAIT : int ();

Get the constant value of C<MSG_DONTWAIT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_EOR

  static method MSG_EOR : int ();

Get the constant value of C<MSG_EOR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_ERRQUEUE

  static method MSG_ERRQUEUE : int ();

Get the constant value of C<MSG_ERRQUEUE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_ERRQUIE

  static method MSG_ERRQUIE : int ();

Get the constant value of C<MSG_ERRQUIE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_MORE

  static method MSG_MORE : int ();

Get the constant value of C<MSG_MORE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_NOSIGNAL

  static method MSG_NOSIGNAL : int ();

Get the constant value of C<MSG_NOSIGNAL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_OOB

  static method MSG_OOB : int ();

Get the constant value of C<MSG_OOB>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_PEEK

  static method MSG_PEEK : int ();

Get the constant value of C<MSG_PEEK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_TRUNC

  static method MSG_TRUNC : int ();

Get the constant value of C<MSG_TRUNC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_WAITALL

  static method MSG_WAITALL : int ();

Get the constant value of C<MSG_WAITALL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 PF_INET

  static method PF_INET : int ();

Get the constant value of C<PF_INET>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 PF_UNIX

  static method PF_UNIX : int ();

Get the constant value of C<PF_UNIX>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SCM_RIGHTS

  static method SCM_RIGHTS : int ();

Get the constant value of C<SCM_RIGHTS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SCM_SECURITY

  static method SCM_SECURITY : int ();

Get the constant value of C<SCM_SECURITY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOCK_CLOEXEC

  static method SOCK_CLOEXEC : int ();

Get the constant value of C<SOCK_CLOEXEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOCK_DGRAM

  static method SOCK_DGRAM : int ();

Get the constant value of C<SOCK_DGRAM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOCK_NONBLOCK

  static method SOCK_NONBLOCK : int ();

Get the constant value of C<SOCK_NONBLOCK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOCK_PACKET

  static method SOCK_PACKET : int ();

Get the constant value of C<SOCK_PACKET>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOCK_RAW

  static method SOCK_RAW : int ();

Get the constant value of C<SOCK_RAW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOCK_RDM

  static method SOCK_RDM : int ();

Get the constant value of C<SOCK_RDM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOCK_SEQPACKET

  static method SOCK_SEQPACKET : int ();

Get the constant value of C<SOCK_SEQPACKET>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOCK_STREAM

  static method SOCK_STREAM : int ();

Get the constant value of C<SOCK_STREAM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOL_IP

  static method SOL_IP : int ();

Get the constant value of C<SOL_IP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOL_SOCKET

  static method SOL_SOCKET : int ();

Get the constant value of C<SOL_SOCKET>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SOMAXCONN

  static method SOMAXCONN : int ();

Get the constant value of C<SOMAXCONN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_BROADCAST

  static method SO_BROADCAST : int ();

Get the constant value of C<SO_BROADCAST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_EE_OFFENDER

  static method SO_EE_OFFENDER : int ();

Get the constant value of C<SO_EE_OFFENDER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_EE_ORIGIN_ICMP

  static method SO_EE_ORIGIN_ICMP : int ();

Get the constant value of C<SO_EE_ORIGIN_ICMP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_EE_ORIGIN_ICMP6

  static method SO_EE_ORIGIN_ICMP6 : int ();

Get the constant value of C<SO_EE_ORIGIN_ICMP6>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_EE_ORIGIN_LOCAL

  static method SO_EE_ORIGIN_LOCAL : int ();

Get the constant value of C<SO_EE_ORIGIN_LOCAL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_EE_ORIGIN_NONE

  static method SO_EE_ORIGIN_NONE : int ();

Get the constant value of C<SO_EE_ORIGIN_NONE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_ERROR

  static method SO_ERROR : int ();

Get the constant value of C<SO_ERROR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_KEEPALIVE

  static method SO_KEEPALIVE : int ();

Get the constant value of C<SO_KEEPALIVE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_PEERSEC

  static method SO_PEERSEC : int ();

Get the constant value of C<SO_PEERSEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_REUSEADDR

  static method SO_REUSEADDR : int ();

Get the constant value of C<SO_REUSEADDR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_CORK

  static method TCP_CORK : int ();

Get the constant value of C<TCP_CORK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 UDP_CORK

  static method UDP_CORK : int ();

Get the constant value of C<UDP_CORK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 INET_ADDRSTRLEN

  static method INET_ADDRSTRLEN : int ();

Get the constant value of C<INET_ADDRSTRLEN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 INET6_ADDRSTRLEN

  static method INET6_ADDRSTRLEN : int ();

Get the constant value of C<INET6_ADDRSTRLEN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPPROTO_IPV6

  static method IPPROTO_IPV6 : int ();

Get the constant value of C<IPPROTO_IPV6>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPPROTO_ICMP

  static method IPPROTO_ICMP : int ();

Get the constant value of C<IPPROTO_ICMP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_ADDRFORM

  static method IPV6_ADDRFORM : int ();

Get the constant value of C<IPV6_ADDRFORM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_ADD_MEMBERSHIP

  static method IPV6_ADD_MEMBERSHIP : int ();

Get the constant value of C<IPV6_ADD_MEMBERSHIP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_AUTHHDR

  static method IPV6_AUTHHDR : int ();

Get the constant value of C<IPV6_AUTHHDR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_DROP_MEMBERSHIP

  static method IPV6_DROP_MEMBERSHIP : int ();

Get the constant value of C<IPV6_DROP_MEMBERSHIP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_DSTOPS

  static method IPV6_DSTOPS : int ();

Get the constant value of C<IPV6_DSTOPS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_DSTOPTS

  static method IPV6_DSTOPTS : int ();

Get the constant value of C<IPV6_DSTOPTS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_FLOWINFO

  static method IPV6_FLOWINFO : int ();

Get the constant value of C<IPV6_FLOWINFO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_HOPLIMIT

  static method IPV6_HOPLIMIT : int ();

Get the constant value of C<IPV6_HOPLIMIT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_HOPOPTS

  static method IPV6_HOPOPTS : int ();

Get the constant value of C<IPV6_HOPOPTS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_MTU

  static method IPV6_MTU : int ();

Get the constant value of C<IPV6_MTU>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_MTU_DISCOVER

  static method IPV6_MTU_DISCOVER : int ();

Get the constant value of C<IPV6_MTU_DISCOVER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_MULTICAST_HOPS

  static method IPV6_MULTICAST_HOPS : int ();

Get the constant value of C<IPV6_MULTICAST_HOPS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_MULTICAST_IF

  static method IPV6_MULTICAST_IF : int ();

Get the constant value of C<IPV6_MULTICAST_IF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_MULTICAST_LOOP

  static method IPV6_MULTICAST_LOOP : int ();

Get the constant value of C<IPV6_MULTICAST_LOOP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_PKTINFO

  static method IPV6_PKTINFO : int ();

Get the constant value of C<IPV6_PKTINFO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_RECVERR

  static method IPV6_RECVERR : int ();

Get the constant value of C<IPV6_RECVERR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_ROUTER_ALERT

  static method IPV6_ROUTER_ALERT : int ();

Get the constant value of C<IPV6_ROUTER_ALERT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_RTHDR

  static method IPV6_RTHDR : int ();

Get the constant value of C<IPV6_RTHDR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_UNICAST_HOPS

  static method IPV6_UNICAST_HOPS : int ();

Get the constant value of C<IPV6_UNICAST_HOPS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IPV6_V6ONLY

  static method IPV6_V6ONLY : int ();

Get the constant value of C<IPV6_V6ONLY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 PF_INET6

  static method PF_INET6 : int ();

Get the constant value of C<PF_INET6>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_ACCEPTCONN

  static method SO_ACCEPTCONN : int ();

Get the constant value of C<SO_ACCEPTCONN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_ATTACH_BPF

  static method SO_ATTACH_BPF : int ();

Get the constant value of C<SO_ATTACH_BPF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_ATTACH_FILTER

  static method SO_ATTACH_FILTER : int ();

Get the constant value of C<SO_ATTACH_FILTER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_ATTACH_REUSEPORT_CBPF

  static method SO_ATTACH_REUSEPORT_CBPF : int ();

Get the constant value of C<SO_ATTACH_REUSEPORT_CBPF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_ATTACH_REUSEPORT_EBPF

  static method SO_ATTACH_REUSEPORT_EBPF : int ();

Get the constant value of C<SO_ATTACH_REUSEPORT_EBPF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_BINDTODEVICE

  static method SO_BINDTODEVICE : int ();

Get the constant value of C<SO_BINDTODEVICE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_BSDCOMPAT

  static method SO_BSDCOMPAT : int ();

Get the constant value of C<SO_BSDCOMPAT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_BUSY_POLL

  static method SO_BUSY_POLL : int ();

Get the constant value of C<SO_BUSY_POLL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_DEBUG

  static method SO_DEBUG : int ();

Get the constant value of C<SO_DEBUG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_DETACH_BPF

  static method SO_DETACH_BPF : int ();

Get the constant value of C<SO_DETACH_BPF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_DETACH_FILTER

  static method SO_DETACH_FILTER : int ();

Get the constant value of C<SO_DETACH_FILTER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_DOMAIN

  static method SO_DOMAIN : int ();

Get the constant value of C<SO_DOMAIN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_DONTROUTE

  static method SO_DONTROUTE : int ();

Get the constant value of C<SO_DONTROUTE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_INCOMING_CPU

  static method SO_INCOMING_CPU : int ();

Get the constant value of C<SO_INCOMING_CPU>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_INCOMING_NAPI_ID

  static method SO_INCOMING_NAPI_ID : int ();

Get the constant value of C<SO_INCOMING_NAPI_ID>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_LINGER

  static method SO_LINGER : int ();

Get the constant value of C<SO_LINGER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_LOCK_FILTER

  static method SO_LOCK_FILTER : int ();

Get the constant value of C<SO_LOCK_FILTER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_MARK

  static method SO_MARK : int ();

Get the constant value of C<SO_MARK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_OOBINLINE

  static method SO_OOBINLINE : int ();

Get the constant value of C<SO_OOBINLINE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_PASSCRED

  static method SO_PASSCRED : int ();

Get the constant value of C<SO_PASSCRED>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_PASSSEC

  static method SO_PASSSEC : int ();

Get the constant value of C<SO_PASSSEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_PEEK_OFF

  static method SO_PEEK_OFF : int ();

Get the constant value of C<SO_PEEK_OFF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_PEERCRED

  static method SO_PEERCRED : int ();

Get the constant value of C<SO_PEERCRED>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_PRIORITY

  static method SO_PRIORITY : int ();

Get the constant value of C<SO_PRIORITY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_PROTOCOL

  static method SO_PROTOCOL : int ();

Get the constant value of C<SO_PROTOCOL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_RCVBUF

  static method SO_RCVBUF : int ();

Get the constant value of C<SO_RCVBUF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_RCVBUFFORCE

  static method SO_RCVBUFFORCE : int ();

Get the constant value of C<SO_RCVBUFFORCE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_RCVLOWAT

  static method SO_RCVLOWAT : int ();

Get the constant value of C<SO_RCVLOWAT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_RCVTIMEO

  static method SO_RCVTIMEO : int ();

Get the constant value of C<SO_RCVTIMEO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_REUSEPORT

  static method SO_REUSEPORT : int ();

Get the constant value of C<SO_REUSEPORT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_RXQ_OVFL

  static method SO_RXQ_OVFL : int ();

Get the constant value of C<SO_RXQ_OVFL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_SELECT_ERR_QUEUE

  static method SO_SELECT_ERR_QUEUE : int ();

Get the constant value of C<SO_SELECT_ERR_QUEUE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_SNDBUF

  static method SO_SNDBUF : int ();

Get the constant value of C<SO_SNDBUF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_SNDBUFFORCE

  static method SO_SNDBUFFORCE : int ();

Get the constant value of C<SO_SNDBUFFORCE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_SNDLOWAT

  static method SO_SNDLOWAT : int ();

Get the constant value of C<SO_SNDLOWAT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_SNDTIMEO

  static method SO_SNDTIMEO : int ();

Get the constant value of C<SO_SNDTIMEO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_TIMESTAMP

  static method SO_TIMESTAMP : int ();

Get the constant value of C<SO_TIMESTAMP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_TIMESTAMPNS

  static method SO_TIMESTAMPNS : int ();

Get the constant value of C<SO_TIMESTAMPNS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SO_TYPE

  static method SO_TYPE : int ();

Get the constant value of C<SO_TYPE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_BCAST

  static method MSG_BCAST : int ();

Get the constant value of C<MSG_BCAST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_COPY

  static method MSG_COPY : int ();

Get the constant value of C<MSG_COPY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_EXCEPT

  static method MSG_EXCEPT : int ();

Get the constant value of C<MSG_EXCEPT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_MCAST

  static method MSG_MCAST : int ();

Get the constant value of C<MSG_MCAST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 MSG_NOERROR

  static method MSG_NOERROR : int ();

Get the constant value of C<MSG_NOERROR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SHUT_RD

  static method SHUT_RD : int ();

Get the constant value of C<SHUT_RD>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SHUT_WR

  static method SHUT_WR : int ();

Get the constant value of C<SHUT_WR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SHUT_RDWR

  static method SHUT_RDWR : int ();

Get the constant value of C<SHUT_RDWR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_CONGESTION

  static method TCP_CONGESTION : int ();

Get the constant value of C<TCP_CONGESTION>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_DEFER_ACCEPT

  static method TCP_DEFER_ACCEPT : int ();

Get the constant value of C<TCP_DEFER_ACCEPT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_INFO

  static method TCP_INFO : int ();

Get the constant value of C<TCP_INFO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_KEEPCNT

  static method TCP_KEEPCNT : int ();

Get the constant value of C<TCP_KEEPCNT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_KEEPIDLE

  static method TCP_KEEPIDLE : int ();

Get the constant value of C<TCP_KEEPIDLE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_KEEPINTVL

  static method TCP_KEEPINTVL : int ();

Get the constant value of C<TCP_KEEPINTVL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_LINGER2

  static method TCP_LINGER2 : int ();

Get the constant value of C<TCP_LINGER2>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_MAXSEG

  static method TCP_MAXSEG : int ();

Get the constant value of C<TCP_MAXSEG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_NODELAY

  static method TCP_NODELAY : int ();

Get the constant value of C<TCP_NODELAY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_QUICKACK

  static method TCP_QUICKACK : int ();

Get the constant value of C<TCP_QUICKACK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_SYNCNT

  static method TCP_SYNCNT : int ();

Get the constant value of C<TCP_SYNCNT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_SYNQ_HSIZE

  static method TCP_SYNQ_HSIZE : int ();

Get the constant value of C<TCP_SYNQ_HSIZE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_USER_TIMEOUT

  static method TCP_USER_TIMEOUT : int ();

Get the constant value of C<TCP_USER_TIMEOUT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TCP_WINDOW_CLAMP

  static method TCP_WINDOW_CLAMP : int ();

Get the constant value of C<TCP_WINDOW_CLAMP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IN6ADDR_ANY

  static method IN6ADDR_ANY : int ();

Get the value initialized by C<IN6ADDR_ANY_INIT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 IN6ADDR_LOOPBACK

  static method IN6ADDR_LOOPBACK : int ();

Get the value initialized by C<IN6ADDR_LOOPBACK_INIT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NI_MAXHOST

  static method NI_MAXHOST : int ();

Get the constant value of C<NI_MAXHOST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 NI_MAXSERV

  static method NI_MAXSERV : int ();

Get the constant value of C<NI_MAXSERV>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_ADDRESS

  static method ICMP_ADDRESS : int ();

Get the constant value of C<ICMP_ADDRESS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_DEST_UNREACH

  static method ICMP_DEST_UNREACH : int ();

Get the constant value of C<ICMP_DEST_UNREACH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_ECHO

  static method ICMP_ECHO : int ();

Get the constant value of C<ICMP_ECHO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_ECHOREPLY

  static method ICMP_ECHOREPLY : int ();

Get the constant value of C<ICMP_ECHOREPLY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_ECHOREQUEST

  static method ICMP_ECHOREQUEST : int ();

Get the constant value of C<ICMP_ECHOREQUEST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_FILTER

  static method ICMP_FILTER : int ();

Get the constant value of C<ICMP_FILTER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_FRAG_NEEDED

  static method ICMP_FRAG_NEEDED : int ();

Get the constant value of C<ICMP_FRAG_NEEDED>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_PARAMETERPROB

  static method ICMP_PARAMETERPROB : int ();

Get the constant value of C<ICMP_PARAMETERPROB>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_REDIRECT

  static method ICMP_REDIRECT : int ();

Get the constant value of C<ICMP_REDIRECT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_SOURCE_QUENCH

  static method ICMP_SOURCE_QUENCH : int ();

Get the constant value of C<ICMP_SOURCE_QUENCH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_TIMESTAMP

  static method ICMP_TIMESTAMP : int ();

Get the constant value of C<ICMP_TIMESTAMP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ICMP_TIME_EXCEEDED

  static method ICMP_TIME_EXCEEDED : int ();

Get the constant value of C<ICMP_TIME_EXCEEDED>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.
