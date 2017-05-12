package POSIX::Socket;

use 5.006;
use strict;
use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT = qw(_socket _close _connect _fcntl _bind _recv _recvfrom _send _sendto _getsockname _sendn _recvn _accept _listen
	_getsockopt _setsockopt);
our $VERSION = '0.09';

require XSLoader;
XSLoader::load('POSIX::Socket', $VERSION);

1;
__END__

=head1 NAME

POSIX::Socket - Low-level perl interface to POSIX sockets

=head1 SYNOPSIS

 use POSIX::Socket
 
 my $rd=_socket(AF_INET, SOCK_DGRAM, 0) or die "socket: $!\n";
 my $wr=_socket(AF_INET, SOCK_DGRAM, 0) or die "socket: $!\n";
 
 my $addr = sockaddr_in(0, inet_aton("127.0.0.1"));
 my $bind_rv=_bind($rd, $addr);
 
 _getsockname($rd, $addr);
 my ($port, $ip) = unpack_sockaddr_in($addr);
 $ip = inet_ntoa($ip);
 die "_getsockname fail!" unless $ip eq "127.0.0.1";
 
 my $ret_val1 = _sendto($wr, $msg, $flags, $addr);
 my $ret_val2 = _recv($rd, $buf, 8192, 0);
 
 _close ($rd);
 _close ($wr);

=head1 DESCRIPTION

The primary purpose of this is to use file descriptors instead of
file handles for socket operations. File descriptors can be shared
between threads and not need dup file handles for each threads.

I hope you enjoyed it.

=head2 EXPORT

 $fd = _socket($socket_family, $socket_type, $protocol);
 
 $rv = _close($fd)
 
 $rv = _fcntl($fildes, $cmd, $arg);
 
 $rv = _bind($fd, $addr);
 
 $rv = _connect($fd, $addr);
 
 $n = _recv($fd, $buffer, $len, $flags);
 
 $n = _recvn($fd, $buffer, $len, $flags);
 
 $rv = _getsockname($fd, $addr);
 
 $n = _send($fd, $buffer, $flags);
 
 $n = _sendn($fd, $buffer, $flags);
 
 $n = _sendto($fd, $buf, $flags, $dest_addr);

 $n = _recvfrom($fd, $buf, $len, $flags, $sock_addr);
 
 $new_fd = _accept($fd);
 
 $rv = _listen($fd, $backlog);
 
 $rv = _getsockopt($fd, $level, $optname, $optval, $optlen);
 
 $rv = _setsockopt($fd, $level, $optname, $optval);

=head1 AUTHOR

Yury Kotlyarov C<yura@cpan.org>

=head1 SEE ALSO

L<POSIX>, L<Socket>

=cut
