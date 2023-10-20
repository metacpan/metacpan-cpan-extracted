use ExtUtils::MakeMaker;

use Socket ":all";

# Names stripped from the Socket Makefile.PL
my @names = (
    qw(
        AF_802 AF_AAL AF_APPLETALK AF_CCITT AF_CHAOS AF_CTF AF_DATAKIT
        AF_DECnet AF_DLI AF_ECMA AF_GOSIP AF_HYLINK AF_IMPLINK AF_INET AF_INET6
        AF_ISO AF_KEY AF_LAST AF_LAT AF_LINK AF_LOCAL AF_MAX AF_NBS AF_NIT
        AF_NS AF_OSI AF_OSINET AF_PUP AF_ROUTE AF_SNA AF_UNIX AF_UNSPEC AF_USER
        AF_WAN AF_X25

        AI_ADDRCONFIG AI_ALL AI_CANONIDN AI_CANONNAME AI_IDN
        AI_NUMERICHOST AI_NUMERICSERV AI_PASSIVE AI_V4MAPPED

        EAI_ADDRFAMILY EAI_AGAIN EAI_BADFLAGS EAI_BADHINTS EAI_FAIL EAI_FAMILY
        EAI_NODATA EAI_NONAME EAI_PROTOCOL EAI_SERVICE EAI_SOCKTYPE EAI_SYSTEM

        IOV_MAX

        IP_ADD_MEMBERSHIP IP_ADD_SOURCE_MEMBERSHIP IP_BIND_ADDRESS_NO_PORT
        IP_DROP_MEMBERSHIP IP_DROP_SOURCE_MEMBERSHIP IP_FREEBIND IP_HDRINCL
        IP_MULTICAST_ALL IP_MULTICAST_IF IP_MULTICAST_LOOP IP_MULTICAST_TTL
        IP_MTU IP_MTU_DISCOVER IP_NODEFRAG IP_OPTIONS IP_RECVERR IP_RECVOPTS
        IP_RECVRETOPTS IP_RETOPTS IP_TOS IP_TRANSPARENT IP_TTL

        IP_PMTUDISC_DO IP_PMTUDISC_DONT IP_PMTUDISC_PROBE IP_PMTUDISC_WANT

        IPTOS_LOWDELAY IPTOS_THROUGHPUT IPTOS_RELIABILITY IPTOS_MINCOST

        IPV6_ADDRFROM IPV6_ADD_MEMBERSHIP IPV6_DROP_MEMBERSHIP IPV6_JOIN_GROUP
        IPV6_LEAVE_GROUP IPV6_MTU IPV6_MTU_DISCOVER IPV6_MULTICAST_HOPS
        IPV6_MULTICAST_IF IPV6_MULTICAST_LOOP IPV6_RECVERR IPV6_ROUTER_ALERT
        IPV6_UNICAST_HOPS IPV6_V6ONLY

        LOCAL_CONNWAIT LOCAL_CREDS LOCAL_OCREDS LOCAL_PEEREID

        MSG_BCAST MSG_BTAG MSG_CTLFLAGS MSG_CTLIGNORE MSG_DONTWAIT MSG_EOF
        MSG_EOR MSG_ERRQUEUE MSG_ETAG MSG_FASTOPEN MSG_FIN MSG_MAXIOVLEN
        MSG_MCAST MSG_NOSIGNAL MSG_RST MSG_SYN MSG_TRUNC MSG_URG MSG_WAITALL
        MSG_WIRE

        NI_DGRAM NI_IDN NI_NAMEREQD NI_NOFQDN NI_NUMERICHOST NI_NUMERICSERV

        PF_802 PF_AAL PF_APPLETALK PF_CCITT PF_CHAOS PF_CTF PF_DATAKIT
        PF_DECnet PF_DLI PF_ECMA PF_GOSIP PF_HYLINK PF_IMPLINK PF_INET PF_INET6
        PF_ISO PF_KEY PF_LAST PF_LAT PF_LINK PF_LOCAL PF_MAX PF_NBS PF_NIT
        PF_NS PF_OSI PF_OSINET PF_PUP PF_ROUTE PF_SNA PF_UNIX PF_UNSPEC PF_USER
        PF_WAN PF_X25

        SCM_CONNECT SCM_CREDENTIALS SCM_CREDS SCM_TIMESTAMP

        SOCK_DGRAM SOCK_RAW SOCK_RDM SOCK_SEQPACKET SOCK_STREAM
        SOCK_NONBLOCK SOCK_CLOEXEC

        SOL_SOCKET 

        SOMAXCONN

        SO_ACCEPTCONN SO_ATTACH_FILTER SO_BACKLOG SO_BINDTODEVICE SO_BROADCAST
        SO_BSDCOMPAT SO_BUSY_POLL SO_CHAMELEON SO_DEBUG SO_DETACH_FILTER
        SO_DGRAM_ERRIND SO_DOMAIN SO_DONTLINGER SO_DONTROUTE SO_ERROR SO_FAMILY
        SO_INCOMING_CPU SO_INCOMING_NAPI_ID SO_KEEPALIVE SO_LINGER
        SO_LOCK_FILTER SO_MARK SO_OOBINLINE SO_PASSCRED SO_PASSIFNAME
        SO_PEEK_OFF SO_PEERCRED SO_PRIORITY SO_PROTOCOL SO_PROTOTYPE SO_RCVBUF
        SO_RCVBUFFORCE SO_RCVLOWAT SO_RCVTIMEO SO_REUSEADDR SO_REUSEPORT
        SO_RXQ_OVFL SO_SECURITY_AUTHENTICATION SO_SECURITY_ENCRYPTION_NETWORK
        SO_SECURITY_ENCRYPTION_TRANSPORT SO_SNDBUF SO_SNDBUFFORCE SO_SNDLOWAT
        SO_SNDTIMEO SO_STATE SO_TIMESTAMP SO_TYPE SO_USELOOPBACK SO_XOPEN
        SO_XSE

        TCP_CONGESTION TCP_CONNECTIONTIMEOUT TCP_CORK TCP_DEFER_ACCEPT
        TCP_FASTOPEN TCP_INFO TCP_INIT_CWND TCP_KEEPALIVE TCP_KEEPCNT
        TCP_KEEPIDLE TCP_KEEPINTVL TCP_LINGER2 TCP_MAXRT TCP_MAXSEG
        TCP_MD5SIG TCP_NODELAY TCP_NOOPT TCP_NOPUSH TCP_QUICKACK
        TCP_SACK_ENABLE TCP_STDURG TCP_SYNCNT TCP_USER_TIMEOUT
        TCP_WINDOW_CLAMP

        UIO_MAXIOV
    ),
    qw(
    IPPROTO_IP
    IPPROTO_IPV6
    IPPROTO_RAW
    IPPROTO_ICMP
    IPPROTO_IGMP
    IPPROTO_TCP
    IPPROTO_UDP
    IPPROTO_GRE
    IPPROTO_ESP
    IPPROTO_AH
    IPPROTO_ICMPV6
    IPPROTO_SCTP
    SHUT_RD
    SHUT_WR
    SHUT_RDWR
    ),

    qw (MSG_CTRUNC MSG_DONTROUTE MSG_OOB MSG_PEEK MSG_PROXY SCM_RIGHTS),
    qw(INADDR_ANY INADDR_LOOPBACK INADDR_NONE INADDR_BROADCAST),
    qw(IN6ADDR_ANY IN6ADDR_LOOPBACK)
);


# Attempt extract all symbols, and create a new file containing only the
# defined symbols


my $code=
'use v5.36;
package Socket::More::Constants;
our $VERSION=\'v0.1.0\';
my %table;
BEGIN {%table=(
';

use Scalar::Util qw<looks_like_number>;;
my @valid;
for(sort @names){
  no strict "refs";
  my $name="Socket::$_";
  local $@;
  my $res=eval {*{$name}->()};
  unless($@){
    push @valid, $_;
    if(looks_like_number $res){
      $code.=" $_ => $res,\n";
    }
    else {
      $code.=" $_ => \"".
        join("", map({'\x'.unpack("H*", $_)} split(//, $res)))
        ."\",\n"

    }
  }
}

$code.=');}
use constant::more %table;
use Export::These keys %table;
1;';


# write filein
#say $code;
open my $fh, ">", "lib/Socket/More/Constants.pm" or die "Could not open file for writing";
print $fh $code;
close $fh;





# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Socket::More::Constants',
	VERSION_FROM      => 'lib/Socket/More/Constants.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
	PREREQ_PM         => {
    "Export::These"=>0,
    "constant::more"=>"v0.3.0"

	}, # e.g., Module::Name => 1.1
	MIN_PERL_VERSION=>"v5.36.0",
	TEST_REQUIRES	=>{
		'Data::Cmp'=>0
	},
	ABSTRACT_FROM     => 'lib/Socket/More/Constants.pod', # retrieve abstract from module
	AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
	LICENSE           => 'mit',
	LIBS              => [''], # e.g., '-lm'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-socket-more-constants.git",
				web => "http://github.com/drclaw1394/perl-socket-more-constants",
			}
		}
	}
	
);
