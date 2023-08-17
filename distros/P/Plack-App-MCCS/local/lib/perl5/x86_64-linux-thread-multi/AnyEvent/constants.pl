# automatically generated from constants.pl.PL
sub AnyEvent::common_sense {
   local $^W;
   ${^WARNING_BITS} ^= ${^WARNING_BITS} ^ "\x0c\x3f\x33\x00\x0f\xf0\x0f\xc0\xf0\xfc\x33\x00\x00\xc0\x00\x00\x00\x00\x00\x00";
   $^H |= 0x7c0;
}
# generated for perl 5.038000 built for x86_64-linux-thread-multi
package AnyEvent;
sub CYGWIN(){0}
sub WIN32(){0}
sub F_SETFD(){2}
sub F_SETFL(){4}
sub O_NONBLOCK(){2048}
sub FD_CLOEXEC(){1}
package AnyEvent::Base;
sub WNOHANG(){1}
package AnyEvent::IO;
sub O_RDONLY(){0}
sub O_WRONLY(){1}
sub O_RDWR(){2}
sub O_CREAT(){64}
sub O_EXCL(){128}
sub O_TRUNC(){512}
sub O_APPEND(){1024}
package AnyEvent::Util;
sub WSAEINVAL(){-1e+99}
sub WSAEWOULDBLOCK(){-1e+99}
sub WSAEINPROGRESS(){-1e+99}
sub _AF_INET6(){10}
package AnyEvent::Socket;
sub MSG_DONTWAIT(){64}
sub MSG_FASTOPEN(){536870912}
sub MSG_MORE(){32768}
sub MSG_NOSIGNAL(){16384}
sub TCP_CONGESTION(){13}
sub TCP_CONNECTIONTIMEOUT(){undef}
sub TCP_CORK(){3}
sub TCP_DEFER_ACCEPT(){9}
sub TCP_FASTOPEN(){23}
sub TCP_INFO(){11}
sub TCP_INIT_CWND(){undef}
sub TCP_KEEPALIVE(){undef}
sub TCP_KEEPCNT(){6}
sub TCP_KEEPIDLE(){4}
sub TCP_KEEPINIT(){undef}
sub TCP_KEEPINTVL(){5}
sub TCP_LINGER2(){8}
sub TCP_MAXSEG(){2}
sub TCP_MD5SIG(){14}
sub TCP_NOOPT(){undef}
sub TCP_NOPUSH(){undef}
sub TCP_QUICKACK(){12}
sub TCP_SACK_ENABLE(){undef}
sub TCP_SYNCNT(){7}
sub TCP_WINDOW_CLAMP(){10}
1;
