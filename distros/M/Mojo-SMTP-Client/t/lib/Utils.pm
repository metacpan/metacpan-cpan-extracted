package Utils;

use strict;
use IO::Socket 'CRLF';
use Socket;
use POSIX 'WNOHANG';

use constant DEBUG => $ENV{MOJO_SMTP_TEST_DEBUG};
use constant TLS => scalar eval "use IO::Socket::SSL 0.98; 1";

$SIG{CHLD} = sub {
	my $pid;
	do { $pid = waitpid(-1, WNOHANG) } while $pid > 0;
};

sub make_smtp_server {
	my $tls = shift;
	
	my @opts = (Listen => 10);
	my $class;
	if ($tls) {
		$class = 'IO::Socket::SSL';
		push @opts, SSL_cert_file => 't/cert/server.crt',
		            SSL_key_file  => 't/cert/server.key';
	}
	else {
		$class = 'IO::Socket::INET';
	}
	my $srv = $class->new(@opts)
		or die $@;
	
	socketpair(my $sock1, my $sock2, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
		or die $!;
	
	defined(my $child = fork())
		or die $!;
	
	if ($child == 0) {
		while (1) {
			my $clt = $srv->accept() or next;
			syswrite($sock2, 'CONNECT'.CRLF);
			
			while (my $resp = <$sock2>) {
				syswrite($clt, $resp) && DEBUG && warn "[$clt] <- $resp" if $resp =~ /^\d+/;
				next if $resp =~ /^\d+-/;
				if ($resp =~ /!quit\s*$/) {
					warn "[$clt] !quit\n" if DEBUG;
					$clt->close();
					last;
				}
				elsif ($resp =~ /!starttls\s*$/) {
					warn "[$clt] !starttls\n" if DEBUG;
					IO::Socket::SSL->start_SSL($clt,
						SSL_server      => 1,
						SSL_cert_file   => 't/cert/server.crt',
						SSL_key_file    => 't/cert/server.key'
					) or die $IO::Socket::SSL::SSL_ERROR;
				}
				
				my $cmd = <$clt> or last;
				warn "[$clt] -> $cmd" if DEBUG;
				syswrite($sock2, $cmd);
			}
		}
		exit;
	}
	
	return ($child, $sock1, $srv->sockhost eq '0.0.0.0' ? '127.0.0.1' : $srv->sockhost, $srv->sockport);
}

1;
