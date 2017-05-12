package Net::DNS::Native;

use strict;
use warnings;
use DynaLoader;
use Socket ();
use Config;

our $VERSION = '0.15';

use constant {
	INET_ATON     => 0,
	INET_PTON     => 1,
	GETHOSTBYNAME => 2,
	GETADDRINFO   => 3,
	NEED_RTLD_GLOBAL => $Config{osname} =~ /linux/i && 
	   !($Config{usethreads} || $Config{libs} =~ /-l?pthread\b/ || $Config{ldflags} =~ /-l?pthread\b/)
};

our @ISA = 'DynaLoader';
sub dl_load_flags {
	if (NEED_RTLD_GLOBAL) {
		return 0x01;
	}
	
	return 0;
}
DynaLoader::bootstrap('Net::DNS::Native');
if (NEED_RTLD_GLOBAL && &_is_non_safe_symbols_loaded) {
	die sprintf(
"***********************************************************************
Some package defined non thread safe symbols which %s uses internally
Please make sure you are not placed loading of modules like IO::Socket::IP
before this one and not called functions like getaddrinfo(), gethostbyname(),
inet_aton() before loading of %s
************************************************************************", __PACKAGE__, __PACKAGE__);
}

sub _fd2socket($) {
	open my $sock, '+<&=' . $_[0]
		or die "Can't transform file descriptor to handle: ", $!;
	$sock;
}

sub getaddrinfo {
	my $self = shift;
	_fd2socket $self->_getaddrinfo($_[0], $_[1], $_[2], GETADDRINFO);
}

sub inet_aton {
	my $self = shift;
	_fd2socket $self->_getaddrinfo($_[0], undef, {family => Socket::AF_INET, socktype => Socket::SOCK_STREAM}, INET_ATON);
}

sub inet_pton {
	my $self = shift;
	_fd2socket $self->_getaddrinfo($_[1], undef, {family => $_[0], socktype => Socket::SOCK_STREAM}, INET_PTON);
}

sub gethostbyname {
	my $self = shift;
	_fd2socket $self->_getaddrinfo($_[0], undef, {family => Socket::AF_INET, flags => Socket::AI_CANONNAME, socktype => Socket::SOCK_STREAM}, GETHOSTBYNAME);
}

sub get_result {
	my ($self, $sock) = @_;
	
	my ($type, $err, @res) =  $self->_get_result(fileno($sock));
	
	if ($type == GETADDRINFO) {
		return ($err, @res);
	}
	
	if ($type == INET_ATON || $type == INET_PTON || (!wantarray() && $type == GETHOSTBYNAME)) {
		return
		  $err ? undef :
		  ( $res[0]{family} == Socket::AF_INET ?
		     Socket::unpack_sockaddr_in($res[0]{addr}) :
		     Net::DNS::Native::unpack_sockaddr_in6($res[0]{addr}) )[1];
	}
	
	if ($type == GETHOSTBYNAME) {
		return
		  $err ? () : 
		  ($res[0]{canonname}, undef, Socket::AF_INET, length($res[0]{addr}), map { (Socket::unpack_sockaddr_in($_->{addr}))[1] } @res);
	}
}

sub timedout {
	my ($self, $sock) = @_;
	$self->_timedout($sock, fileno($sock));
}

1;

__END__

=pod

=head1 NAME

Net::DNS::Native - non-blocking system DNS resolver

=head1 SYNOPSIS

=over

	use Net::DNS::Native;
	use IO::Select;
	use Socket;
	
	my $dns = Net::DNS::Native->new();
	my $sock = $dns->getaddrinfo("google.com");
	
	my $sel = IO::Select->new($sock);
	$sel->can_read(); # wait until resolving done
	my ($err, @res) = $dns->get_result($sock);
	die "Resolving failed: ", $err if ($err);
	
	for my $r (@res) {
		warn "google.com has ip ",
			$r->{family} == AF_INET ?
				inet_ntoa((unpack_sockaddr_in($r->{addr}))[1]) :                   # IPv4
				Socket::inet_ntop(AF_INET6, (unpack_sockaddr_in6($r->{addr}))[1]); # IPv6
	}

=back

=over

	use Net::DNS::Native;
	use AnyEvent;
	use Socket;
	
	my $dns = Net::DNS::Native->new;
	
	my $cv = AnyEvent->condvar;
	$cv->begin;
	
	for my $host ('google.com', 'google.ru', 'google.cy') {
		my $fh = $dns->inet_aton($host);
		$cv->begin;
		
		my $w; $w = AnyEvent->io(
			fh   => $fh,
			poll => 'r',
			cb   => sub {
				my $ip = $dns->get_result($fh);
				warn $host, $ip ? " has ip " . inet_ntoa($ip) : " has no ip";
				$cv->end;
				undef $w;
			}
		)
	}
	
	$cv->end;
	$cv->recv;

=back

=head1 DESCRIPTION

This class provides several methods for host name resolution. It is designed to be used with event loops. All resolving are done
by getaddrinfo(3) implemented in your system library. Since getaddrinfo() is blocking function and we don't want to block,
calls to this function will be done in separate thread. This class uses system native threads and not perl threads. So overhead
shouldn't be too big.

=head1 INSTALLATION WARNING

For some platforms to support threaded extensions like this one your perl should be linked with threads library. At the
installation time this module will check is your perl is good enough and will not install if not.

If it will fail to install use instructions listed below.

One of the possible solution to make your perl compatible with this module is to build perl with perl threads support
using C<-Dusethreads> for C<Configure> script. Other solution is to use C<-A prepend:libswanted="pthread ">, which will
just link non-threaded perl with pthreads.

On Linux with perl not linked with pthreads this module may die with appropriate message at require time. This may happen
if you are called some functions from system library related to DNS operations before loading of C<Net::DNS::Native> (or some module,
like C<IO::Socket::IP>, that you are already loaded, called it internally). So, on such perl C<use IO::Socket::IP; use Net::DNS::Native> may fail, but
C<use Net::DNS::Native; use IO::Socket::IP> will success. The reason of such check inside C<Net::DNS::Native> is that calls to this
functions (gethostbyname, getprotobyname, inet_aton, getaddrinfo, ...) will cause loading of non-thread safe versions of DNS related
stuff and C<Net::DNS::Native> loaded after that will not be able to override this with thread safe versions. So, at one moment your
program will simply exit with segfault. This is why this check and rule are very important.

=head1 METHODS

=head2 new

This is a class constructor. Accepts this optional parameters:

=over

=item pool => $size

If $size>0 will create thread pool with size=$size which will make resolving job. Otherwise will use default behavior:
create and finish thread for each resolving request. If thread pool is not enough big to process all supplied requests, than this
requests will be queued until one of the threads will become free to process next request from the queue.

=item extra_thread => $bool

If pool option specified and $bool has true value will create temporary extra thread for each request that can't be handled by the
pool (when all workers in the pool are busy) instead of pushing it to the queue. This temporary thread will be finished immediatly
after it will process request.

=item notify_on_begin => $bool

Extra mechanizm to notify caller that resolving for some host started. This is usefull for those who uses thread pool without C<extra_thread>
option. When pool becomes full new queries will be queued, so you can specify C<$bool> with true value if you want to receive notifications
when resolving will be really started. To notify it will simply make C<$handle> received by methods below readable. After that you will need to read
data from this handle to make it non readable again, so you can receive next notification, when host resolving will be done. There will be 1 byte
of data which you should read. C<"1"> for notification about start of the resolving and C<"2"> for notification about finish of the resolving.

	my $dns = Net::DNS::Native->new(pool => 1, notify_on_begin => 1);
	my $handle = $dns->inet_aton("google.com");
	my $sel = IO::Select->new($handle);
	$sel->can_read(); # wait "begin" notification
	sysread($handle, my $buf, 1); # $buf eq "1", $handle is not readable again
	$sel->can_read(); # wait "finish" notification
	# resolving done
	# we can sysread($handle, $buf, 1); again and $buf will be eq "2"
	# but this is not necessarily
	my $ip = $dns->get_result($handle);

=back

=head2 getaddrinfo($host, $service, $hints)

This is the most powerfull method. May resolve host to both IPv4 and IPv6 addresses. For full documentation see L<getaddrinfo()|Socket/"($err, @result) = getaddrinfo $host, $service, [$hints]">.
This method accepts same parameters but instead of result returns handle on which you need to wait for availability to read.

=head2 inet_pton($family, $host)

This method will resolve $host accordingly to $family, which may be AF_INET to resolve to IPv4 or AF_INET6 to resolve to IPv6. For full
documentation see L<inet_pton()|Socket/"$address = inet_pton $family, $string">. This method accepts same parameters but instead of result returns
handle on which you need to wait for availability to read.

=head2 inet_aton($host)

This method may be used only for resolving to IPv4. For full documentation see L<inet_aton()|Socket/"$ip_address = inet_aton $string">. This method accepts same
parameters but instead of result returns handle on which you need to wait for availability to read.

=head2 gethostbyname($host)

This method may be used only for resolving to IPv4. For full documentation see L<gethostbyname()|http://perldoc.perl.org/5.14.0/functions/gethostbyname.html>.
This method accepts same parameters but instead of result returns handle on which you need to wait for availability to read.

=head2 get_result($handle)

After handle returned by methods above will became ready for read you should call this method with handle as argument. It will
return results appropriate to the method which returned this handle. For C<getaddrinfo> this will be C<($err, @res)> list. For
C<inet_pton> and C<inet_aton> C<$packed_address> or C<undef>. For C<gethostbyname()> C<$packed_address> or C<undef> in scalar context and
C<($name,$aliases,$addrtype,$length,@addrs)> in list context.

B<NOTE:> it is important to call get_result() on returned handle when it will become ready for read. Because this method destroys resources
associated with this handle. Otherwise you will get memory leaks.

=head2 timedout($handle)

Mark resolving operation associated with this handle as timed out. This will not interrupt resolving operation (because there is no way to interrupt getaddrinfo(3) correctly),
but will automatically discard any results returned when resolving will be done. So, after C<timedout($handle)> you can forget about C<$handle> and
associated resolving operation. And don't need to call C<get_result($handle)> to destroy resources associated with this handle. Furthermore, if you are using thread pool
and all threads in pool are busy and C<extra_thread> option not specified, but 1 resolving operation from this pool marked as timed out and you'll add one more resolving operation,
this operation will not be queued. Instead of this 1 temporary extra thread will be created to process this operation. So you can think about C<timedout> like about real interrupter of
long running resolving operation. But you are warned how it really works.

=head1 AUTHOR

Oleg G, E<lt>oleg@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
