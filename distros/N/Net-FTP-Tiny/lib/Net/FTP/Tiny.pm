=head1 NAME

Net::FTP::Tiny - minimal FTP client

=head1 SYNOPSIS

	use Net::FTP::Tiny qw(ftp_get);

	$data = ftp_get("ftp://ftp.iana.org/tz/data/iso3166.tab");

=head1 DESCRIPTION

This module provides an easy interface to retrieve files using the FTP
protocol.  The location of a file to retrieve is specified using a URL.
IPv6 is supported, if the optional module L<IO::Socket::IP> is installed.
Only retrieval is supported, not storing or anything more exotic.

=cut

package Net::FTP::Tiny;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.001";

# Set up superclass manually, rather than via "parent", to avoid non-core
# dependency.
use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ftp_get);

=head1 FUNCTIONS

=over

=item ftp_get(URL)

I<URL> must be a URL using the C<ftp> scheme.  The file that it refers to
is retrieved from the FTP server, and its content is returned in the form
of a string of octets.  If any error occurs then the function C<die>s.
Possible errors include the URL being malformed, inability to contact
the FTP server, and the FTP server reporting that the file doesn't exist.

=cut

{
	local $SIG{__DIE__};
	eval("$]" >= 5.008 ? q{
		use utf8 ();
		*_downgrade = \&utf8::downgrade;
	} : q{
		sub _downgrade($) {
			# Logic copied from Scalar::String.  See there
			# for explanation; the code depends on accidents
			# of the Perl 5.6 implementation.
			return if unpack("C", "\xaa".$_[0]) == 170;
			{
				use bytes;
				$_[0] =~ /\A[\x00-\x7f\x80-\xbf\xc2\xc3]*\z/
					or die "Wide character";
			}
			use utf8;
			($_[0]) = ($_[0] =~ /\A([\x00-\xff]*)\z/);
		}
	});
	die $@ unless $@ eq "";
}

sub _croak($) { croak "FTP error: $_[0]" }

#
# FTP URL interpretation is governed by RFC 3986 (generic URI syntax) and
# RFC 1738 (an older URL standard, containing the FTP-specific parts).
# There is no formal specification for the syntax of FTP URLs in the
# context of RFC 3986's base syntax, so this code merges the two in
# what seems like a reasonable manner.  Generally, RFC 3986 is used to
# determine which characters are permitted in each component, and RFC
# 1738 determines higher-level structure.
#

my $safechar_rx = qr/[0-9A-Za-z\-\.\_\~\!\$\&\'\(\)\*\+\,\;\=]/;
my $hexpair_rx = qr/\%[0-9A-Fa-f]{2}/;

my $d8_rx = qr/25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9]/;
my $ipv4_address_rx = qr/$d8_rx\.$d8_rx\.$d8_rx\.$d8_rx/o;

my $h16_rx = qr/[0-9A-Fa-f]{1,4}/;
my $ls32_rx = qr/$h16_rx\:$h16_rx|$ipv4_address_rx/o;
my $ipv6_address_rx = qr/
	(?:)                                     (?:$h16_rx\:){6} $ls32_rx
	|                                   \:\: (?:$h16_rx\:){5} $ls32_rx
	| (?:                    $h16_rx )? \:\: (?:$h16_rx\:){4} $ls32_rx
	| (?: (?:$h16_rx\:){0,1} $h16_rx )? \:\: (?:$h16_rx\:){3} $ls32_rx
	| (?: (?:$h16_rx\:){0,2} $h16_rx )? \:\: (?:$h16_rx\:){2} $ls32_rx
	| (?: (?:$h16_rx\:){0,3} $h16_rx )? \:\: (?:$h16_rx\:)    $ls32_rx
	| (?: (?:$h16_rx\:){0,4} $h16_rx )? \:\:                  $ls32_rx
	| (?: (?:$h16_rx\:){0,5} $h16_rx )? \:\:                  $h16_rx
	| (?: (?:$h16_rx\:){0,6} $h16_rx )? \:\:
/xo;

my $ip_future_rx = qr/[vV][0-9A-Fa-f]+\.(?:$safechar_rx|\:)+/o;
my $ip_literal_rx = qr/\[(?:$ipv6_address_rx|$ip_future_rx)\]/o;
my $hostname_rx = qr/
	(?:[0-9A-Za-z](?:[\-0-9A-Za-z]*[0-9A-Za-z])?\.)*
	[A-Za-z](?:[\-0-9A-Za-z]*[0-9A-Za-z])?
/x;
my $host_rx = qr/$ip_literal_rx|$ipv4_address_rx|$hostname_rx/o;

my $userdata_rx = qr/(?:$safechar_rx|$hexpair_rx)*/o;
my $filename_rx = qr/(?:(?!\;)$safechar_rx|[\:\@]|$hexpair_rx)*/o;

sub _uri_decode($) {
	my($str) = @_;
	$str =~ s/\%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	return $str;
}

sub _parse_ftp_url($) {
	my($url) = @_;
	my($user, $pass, $host, $port, $path, $type) = ($url =~ m/\A
		[fF][tT][pP]\:\/\/
		(?:((?>$userdata_rx))(?:\:((?>$userdata_rx)))?\@)?
		((?>$host_rx))(?:\:([0-9]+)?)?
		(?:((?>(?>\/$filename_rx)+))(?:\;type\=([aAiIdD]))?)?
	\z/xo);
	defined $host or _croak "<$url> is not an ftp URL";
	my @path = defined($path) ? ($path =~ m#/($filename_rx)#og) : ();
	my $filename = pop(@path);
	return {
		(defined($user) ? (username => _uri_decode($user)) : ()),
		(defined($pass) ? (password => _uri_decode($pass)) : ()),
		host => $host,
		port => defined($port) ? 0+$port : 21,
		(defined($path) ? (
			dirs => [ map { _uri_decode($_) } @path ],
			filename => _uri_decode($filename),
		) : ()),
		(defined($type) ? (type => lc($type)) : ()),
	};
}

my $blksize = 0x8000;
my $timeout = 50;

my $socket_class;
sub _socket_class() {
	return $socket_class ||=
		eval { local $SIG{__DIE__};
			require IO::Socket::IP;
			IO::Socket::IP->VERSION(0.08);
			"IO::Socket::IP";
		} || do {
			require IO::Socket::INET;
			IO::Socket::INET->VERSION(1.24);
			"IO::Socket::INET";
		};
}

sub _socket_new($@) {
	my $what = shift(@_);
	return _socket_class()->new(@_) || do {
		my $err = $@;
		chomp $err;
		$err =~ s/\AIO::Socket::[A-Z0-9]+: //;
		$err ne "" or $err = "$socket_class didn't say why";
		_croak "failed to $what: $err";
	};
}

sub _open_tcp($$) {
	my($host, $port) = @_;
	if($host =~ /\A\[v/) {
		_croak "IP addresses from the future not supported";
	}
	if($host =~ /\A\[/) {
		_croak "IPv6 support requires IO::Socket::IP"
			unless _socket_class() eq "IO::Socket::IP";
	}
	my $bare_host = $host =~ /\A\[(.*)\]\z/s ? $1 : $host;
	$port >= 1 && $port <= 65535
		or _croak "failed to connect to $host TCP port $port: ".
			"invalid port number";
	return _socket_new("connect to $host TCP port $port",
		PeerHost => $bare_host,
		PeerPort => $port,
		Proto => "tcp",
		Timeout => $timeout,
	);
}

my $loaded_domains;
my %domain_val_tag;
sub _decode_domain($) {
	my($domval) = @_;
	unless($loaded_domains) {
		require Socket;
		Socket->VERSION(1.72);
		foreach my $tag (qw(INET INET6)) {
			no strict "refs";
			my $sub = *{"Socket::AF_$tag"}{CODE} or next;
			my $val = eval { local $SIG{__DIE__}; $sub->() };
			defined $val and $domain_val_tag{$val} = $tag;
		}
		$loaded_domains = 1;
	}
	my $tag = $domain_val_tag{$domval};
	defined $tag or _croak "unrecognised socket domain";
	return $tag;
}

sub _check_timeout($$$) {
	my($sock, $writing, $what) = @_;
	vec(my $b = "", $sock->fileno, 1) = 1;
	my $s = select($writing ? undef : $b, $writing ? $b : undef, $b,
			$timeout);
	$s >= 1 or _croak "failed to $what: @{[$s ? $! : q(timed out)]}";
}

sub _send_cmd($$) {
	my($ctlconn, $cmd) = @_;
	# This encoding is specified by RFC 2640.  It ensures that
	# a parameter string can be distinguished from the \r\n that
	# terminates the command.
	$cmd =~ s/\r/\r\0/g;
	$cmd .= "\r\n";
	my $len = length($cmd);
	local $SIG{PIPE} = "IGNORE";
	for(my $pos = 0; $pos != $len; ) {
		_check_timeout($ctlconn, 1, "send command");
		my $n = $ctlconn->syswrite($cmd, $len-$pos, $pos);
		defined $n or _croak "failed to send command: $!";
		$pos += $n;
	}
}

sub _recv_reply($$) {
	my($ctlconn, $rbufp) = @_;
	my $content;
	while(1) {
		$$rbufp !~ /\A(?:[0-9]{0,2}[^0-9]|[0-9]{3}[^\-\ ])|\r[^\0\n]/
			or _croak "malformed reply from server";
		if($$rbufp =~ s/\A([0-9]{3} (?>(?>(?>[^\r]+)|\r\0)*))\r\n//) {
			$content = $1;
			last;
		} elsif($$rbufp =~ s/\A
			([0-9]{3})-((?>(?>(?>[^\r]+)|\r\0)*)\r\n
			(?>(?>(?>[^\r]+)|\r\0)*\r\n)*?)
			\1\ ((?:(?>[^\r]+)|\r\0)*)\r\n
		//x) {
			$content = "$1 $2$3";
			last;
		}
		_check_timeout($ctlconn, 0, "receive reply");
		my $n = $ctlconn->sysread($$rbufp, $blksize, length($$rbufp));
		defined $n or _croak "failed to receive reply: $!";
		$n != 0 or _croak "failed to receive reply: unexpected EOF";
	}
	# We don't need to preserve exact character content of reply,
	# so sanitise the reply for use in error messages.  Some servers
	# send the reply code on every line, in the SMTP style.
	my($code) = ($content =~ /\A([0-9]{3})/);
	$content =~ s/\r\n\Q$code\E-/\r\n/g;
	$content =~ s/\r\n/%NL/g;
	$content =~ s/\r\0/\r/g;
	$content =~ s/([^ -~])/sprintf("%%%02X", ord($1))/eg;
	return $content;
}

sub _negotiate_dataconn($$) {
	my($ctlconn, $rbufp) = @_;
	my $pasv = _decode_domain($ctlconn->sockdomain) eq "INET" ?
			"PASV" : "EPSV";
	_send_cmd($ctlconn, $pasv);
	my $r = _recv_reply($ctlconn, $rbufp);
	if($pasv eq "PASV" &&
			$r =~ /\A227 .*?($d8_rx(?:,$d8_rx){5})(?![0-9])/so) {
		my @p = split(/,/, $1);
		my $host = join(".", @p[0..3]);
		my $port = ((0+$p[4]) << 8) | (0+$p[5]);
		my $conn = _open_tcp($host, $port);
		return sub { $conn };
	} elsif($pasv eq "EPSV" &&
			$r =~ /\A229 .*?\(([!-~])\1\1([0-9]+)\1\)/s) {
		my $port = $2;
		my $conn = _open_tcp($ctlconn->peerhost, $port);
		return sub { $conn };
	} elsif($r !~ /\A50[02]/) {
		_croak $r;
	}
	my $lsock = _socket_new("listen on TCP port",
		LocalAddr => $ctlconn->sockhost,
		Proto => "tcp",
		Listen => 128,
		Timeout => $timeout,
	);
	my $domain = _decode_domain($lsock->sockdomain);
	my $myaddr = $lsock->sockhost;
	my $myport = $lsock->sockport;
	my $port_cmd;
	if($domain eq "INET") {
		my @p = (split(/\./, $myaddr), $myport >> 8, $myport & 0xff);
		$port_cmd = "PORT @{[join(q(,), @p)]}";
	} elsif($domain eq "INET6") {
		$port_cmd = "EPRT |2|$myaddr|$myport|";
	} else { _croak "unrecognised socket domain" }
	_send_cmd($ctlconn, $port_cmd);
	$r = _recv_reply($ctlconn, $rbufp);
	$r =~ /\A200/ or _croak $r;
	my $require_peerhost = $ctlconn->peerhost;
	my $require_peerport = $ctlconn->peerport - 1;
	return sub {
		_check_timeout($lsock, 0, "accept TCP connection");
		my $conn = $lsock->accept;
		defined $conn or _croak "failed to accept TCP connection: $!";
		$lsock = undef;
		unless($conn->peerhost eq $require_peerhost &&
				$conn->peerport == $require_peerport) {
			_croak "data connection made by wrong peer";
		}
		return $conn;
	};
}

sub ftp_get($) {
	my($url) = @_;
	_downgrade($url);
	my %params = %{_parse_ftp_url($url)};
	unless(exists $params{username}) {
		$params{username} = "anonymous";
		$params{password} = "-anonymous\@";
	}
	defined $params{filename} or _croak "no path supplied";
	exists $params{type} or $params{type} = "i";
	$params{type} eq "d" and _croak "directory listing not supported";
	my $ctlconn = _open_tcp($params{host}, $params{port});
	my $rbuf = "";
	my $r = _recv_reply($ctlconn, \$rbuf);
	$r =~ /\A120/ and $r = _recv_reply($ctlconn, \$rbuf);
	$r =~ /\A220/ or _croak $r;
	_send_cmd($ctlconn, "USER $params{username}");
	$r = _recv_reply($ctlconn, \$rbuf);
	if($r =~ /\A331/ && exists($params{password})) {
		_send_cmd($ctlconn, "PASS $params{password}");
		$r = _recv_reply($ctlconn, \$rbuf);
	}
	$r =~ /\A230/ or _croak $r;
	foreach my $dir (@{$params{dirs}}) {
		_send_cmd($ctlconn, "CWD $dir");
		$r = _recv_reply($ctlconn, \$rbuf);
		$r =~ /\A250/ or _croak $r;
	}
	if($params{type} eq "i") {
		_send_cmd($ctlconn, "TYPE I");
		$r = _recv_reply($ctlconn, \$rbuf);
		$r =~ /\A200/ or _croak $r;
	}
	my $dataconn_thunk = _negotiate_dataconn($ctlconn, \$rbuf);
	_send_cmd($ctlconn, "RETR $params{filename}");
	$r = _recv_reply($ctlconn, \$rbuf);
	$r =~ /\A1(?:25|50)/ or _croak $r;
	my $dataconn = $dataconn_thunk->();
	$dataconn_thunk = undef;
	my $data = "";
	while(1) {
		_check_timeout($dataconn, 0, "receive data");
		my $n = $dataconn->sysread($data, $blksize, length($data));
		defined $n or _croak "failed to receive data: $!";
		$n == 0 and last;
	}
	$dataconn = undef;
	$r = _recv_reply($ctlconn, \$rbuf);
	$r =~ /\A2(?:26|50)/ or _croak $r;
	return $data;
}

=back

=head1 BUGS

IPv6 support is largely untested.  Reports of experiences with it would
be appreciated.

=head1 SEE ALSO

L<IO::Socket::IP>,
L<Net::FTP>,
L<Net::HTTP::Tiny>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
