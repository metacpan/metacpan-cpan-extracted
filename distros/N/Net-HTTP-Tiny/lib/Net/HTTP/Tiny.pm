=head1 NAME

Net::HTTP::Tiny - minimal HTTP client

=head1 SYNOPSIS

	use Net::HTTP::Tiny qw(http_get);

	$dat = http_get("http://maia.usno.navy.mil/ser7/tai-utc.dat");

=head1 DESCRIPTION

This module provides an easy interface to retrieve files using the HTTP
protocol.  The location of a file to retrieve is specified using a URL.
The module conforms to HTTP/1.1, and follows redirections (up to a limit
of five chained redirections).  Content-MD5 is checked, if the optional
module L<Digest::MD5> is installed.  IPv6 is supported, if the optional
module L<IO::Socket::IP> is installed.  Only retrieval is supported,
not posting or anything more exotic.

=cut

package Net::HTTP::Tiny;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.001";

# Set up superclass manually, rather than via "parent", to avoid non-core
# dependency.
use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(http_get);

=head1 FUNCTIONS

=over

=item http_get(URL)

I<URL> must be a URL using the C<http> scheme.  The file that it refers to
is retrieved from the HTTP server, and its content is returned in the form
of a string of octets.  If any error occurs then the function C<die>s.
Possible errors include the URL being malformed, inability to contact the
HTTP server, and the HTTP server reporting that the file doesn't exist.

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

sub _croak($) { croak "HTTP error: $_[0]" }

#
# HTTP URL interpretation is governed by RFC 3986 (generic URI syntax),
# RFC 2616 (HTTP/1.1, giving top-level syntax), and RFC 2396 (older
# generic URI syntax, to which RFC 2616 refers).  There is no formal
# specification for the syntax of HTTP URLs in the context of RFC 3986's
# base syntax, so this code merges the various sources in what seems like
# a reasonable manner.  Generally, RFC 3986 is used to determine which
# characters are permitted in each component, and RFC 2616 determines
# higher-level structure.
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
my $port_rx = qr/[0-9]+/;

my $http_prefix_rx = qr/[hH][tT][tT][pP]\:\/\//;
my $path_and_query_rx = qr/\/(?:$safechar_rx|[\:\@\/\?]|$hexpair_rx)*/;
my $http_url_rx =
	qr/$http_prefix_rx(?>$host_rx)(?:\:$port_rx?)?$path_and_query_rx?/xo;

sub _parse_http_url($) {
	my($url) = @_;
	my($host, $port, $pathquery) = ($url =~ m/\A
		$http_prefix_rx
		((?>$host_rx))(?:\:($port_rx)?)?
		($path_and_query_rx)?
	\z/xo);
	defined $host or _croak "<$url> is not an http URL";
	return {
		host => $host,
		port => defined($port) ? 0+$port : 80,
		path_and_query => defined($pathquery) ? $pathquery : "/",
	};
}

my $blksize = 0x8000;
my $timeout = 50;

my $socket_class;
sub _open_tcp($$) {
	my($host, $port) = @_;
	if($host =~ /\A\[v/) {
		_croak "IP addresses from the future not supported";
	}
	$socket_class ||=
		eval { local $SIG{__DIE__};
			require IO::Socket::IP;
			IO::Socket::IP->VERSION(0.08);
			"IO::Socket::IP";
		} || do {
			require IO::Socket::INET;
			IO::Socket::INET->VERSION(1.24);
			"IO::Socket::INET";
		};
	if($host =~ /\A\[/) {
		_croak "IPv6 support requires IO::Socket::IP"
			unless $socket_class eq "IO::Socket::IP";
	}
	my $bare_host = $host =~ /\A\[(.*)\]\z/s ? $1 : $host;
	$port >= 1 && $port <= 65535
		or _croak "failed to connect to $host TCP port $port: ".
			"invalid port number";
	return $socket_class->new(
		PeerHost => $bare_host,
		PeerPort => $port,
		Proto => "tcp",
		Timeout => $timeout,
	) || do {
		my $err = $@;
		chomp $err;
		$err =~ s/\AIO::Socket::[A-Z0-9]+: //;
		$err ne "" or $err = "$socket_class didn't say why";
		_croak "failed to connect to $host TCP port $port: $err";
	};
}

sub _check_timeout($$$) {
	my($sock, $writing, $what) = @_;
	vec(my $b = "", $sock->fileno, 1) = 1;
	my $s = select($writing ? undef : $b, $writing ? $b : undef, $b,
			$timeout);
	$s >= 1 or _croak "failed to $what: @{[$s ? $! : q(timed out)]}";
}

sub _recv_more_response($$$) {
	my($conn, $rbufp, $eof_ok) = @_;
	_check_timeout($conn, 0, "receive response");
	my $n = $conn->sysread($$rbufp, $blksize, length($$rbufp));
	defined $n or _croak "failed to receive response: $!";
	$n != 0 and return 1;
	$eof_ok or _croak "failed to receive response: unexpected EOF";
	return 0;
}

sub _recv_line($$) {
	my($conn, $rbufp) = @_;
	while(1) {
		$$rbufp =~ s/\A(.*?)\r?\n//s and return $1;
		_recv_more_response($conn, $rbufp, 0);
	}
}

my $token_rx = qr/[\!\#\$\%\&\'\*\+\-\.0-9A-Z\^\_\`a-z\|\~]+/;
my $quoted_string_rx = qr/\"(?>[\ -\[\]-\~\x80-\xff]+|\\[\ -\~\x80-\xff])*\"/;
my $lws_rx = qr/[\ \t]*/;

sub _recv_headers($$$) {
	my($conn, $rbufp, $h) = @_;
	my $curhdr;
	while(1) {
		my $l = _recv_line($conn, $rbufp);
		if($l =~ /\A[ \t]/) {
			defined $curhdr
				or _croak "malformed response from server";
			$curhdr .= $l;
			next;
		}
		if(defined $curhdr) {
			$curhdr =~ /\A($token_rx)$lws_rx:(.*)\z/so
				or _croak "malformed response from server";
			my($hname, $value) = ($1, $2);
			$hname = lc($hname);
			$h->{$hname} = exists($h->{$hname}) ?
				$h->{$hname}.",".$value : $value;
		}
		$l eq "" and last;
		$curhdr = $l;
	}
}

my $loaded_digest_md5;
sub _http_get_one($) {
	my($url) = @_;
	my $params = _parse_http_url($url);
	my $request = "GET @{[$params->{path_and_query}]} HTTP/1.1\r\n".
		"Connection: close\r\n".
		"Host: @{[$params->{host}]}".
			"@{[$params->{port}==80?q():q(:).$params->{port}]}\r\n".
		"Accept-Encoding: identity\r\n".
		"\r\n";
	my $conn = _open_tcp($params->{host}, $params->{port});
	{
		my $len = length($request);
		local $SIG{PIPE} = "IGNORE";
		for(my $pos = 0; $pos != $len; ) {
			_check_timeout($conn, 1, "send request");
			my $n = $conn->syswrite($request, $len-$pos, $pos);
			defined $n or _croak "failed to send request: $!";
			$pos += $n;
		}
		$request = undef;
	}
	my $rbuf = "";
	my %response;
	while(1) {
		my $l = _recv_line($conn, \$rbuf);
		$l =~ /\A
			HTTP\/[0-9]+\.[0-9]+[\ \t]+
			([0-9]{3}\ [\ -\~\x80-\xff]*)
		\z/x
			or _croak "malformed response from server";
		my $status = $1;
		$status =~ s/([^\ -\~])/sprintf("%%%02X", ord($1))/eg;
		$status =~ /\A(?:[13]|200)/ or _croak $status;
		my %h;
		_recv_headers($conn, \$rbuf, \%h);
		if($status !~ /\A1/) {
			$response{status} = $status;
			$response{headers} = \%h;
			last;
		}
	}
	return \%response unless $response{status} =~ /\A200/;
	my $ce = lc(exists($response{headers}->{"content-encoding"}) ?
		$response{headers}->{"content-encoding"} : "identity");
	$ce =~ /\A${lws_rx}identity${lws_rx}\z/o
		or _croak "unsupported Content-Encoding";
	my $te = lc(exists($response{headers}->{"transfer-encoding"}) ?
		$response{headers}->{"transfer-encoding"} : "identity");
	if($te =~ /\A${lws_rx}chunked${lws_rx}\z/o) {
		$response{body} = "";
		while(1) {
			_recv_line($conn, \$rbuf) =~ /\A
				([0-9A-Fa-f]+)$lws_rx
				(?>
					;$lws_rx$token_rx$lws_rx
					(?>\=$lws_rx
					    (?:$token_rx|$quoted_string_rx)
					    $lws_rx
					)?
				)*
			\z/xo or _croak "malformed chunk";
			my $csize = $1;
			$csize =~ s/\A0+//;
			last if $csize eq "";
			length($csize) <= 8 or _croak "excessive chunk length";
			$csize = hex($csize);
			while(length($rbuf) < $csize) {
				_recv_more_response($conn, \$rbuf, 0);
			}
			$response{body} .= substr($rbuf, 0, $csize, "");
			_recv_line($conn, \$rbuf) eq ""
				or _croak "malformed chunk";
		}
		_recv_headers($conn, \$rbuf, $response{headers});
	} elsif($te !~ /\A${lws_rx}identity${lws_rx}\z/o) {
		_croak "unsupported Transfer-Encoding";
	} elsif(exists $response{headers}->{"content-length"}) {
		$response{headers}->{"content-length"}
				=~ /\A$lws_rx([0-9]+)$lws_rx\z/o
			or _croak "malformed Content-Length";
		my $body_length = $1;
		$body_length < 0xffffffff or _croak "excessive Content-Length";
		$response{body} = $rbuf;
		while(length($response{body}) < $body_length) {
			_recv_more_response($conn, \$response{body}, 0);
		}
		substr $response{body}, $body_length,
			length($response{body})-$body_length, "";
	} else {
		$response{body} = $rbuf;
		1 while _recv_more_response($conn, \$response{body}, 1);
	}
	$conn = undef;
	if(exists $response{headers}->{"content-md5"}) {
		$response{headers}->{"content-md5"}
			=~ /\A$lws_rx([A-Za-z0-9\+\/]{21}[AQgw])\=\=$lws_rx\z/o
				or _croak "malformed Content-MD5";
		my $digest = $1;
		unless(defined $loaded_digest_md5) {
			$loaded_digest_md5 = eval { local $SIG{__DIE__};
				require Digest::MD5;
				Digest::MD5->VERSION(2.17);
				1;
			} ? 1 : 0;
		}
		if($loaded_digest_md5) {
			Digest::MD5::md5_base64($response{body}) eq $digest
				or _croak "Content-MD5 mismatch";
		}
	}
	return \%response;
}

sub http_get($) {
	my($url) = @_;
	_downgrade($url);
	my %seen;
	for(my $redir_limit = 6; $redir_limit--; ) {
		my $response = _http_get_one($url);
		$response->{status} =~ /\A200/ and return $response->{body};
		$seen{$url} = undef;
		my $loc = $response->{headers}->{location};
		defined $loc or _croak "redirection with no target";
		if($loc =~ /\A$lws_rx($http_url_rx)$lws_rx\z/o) {
			$url = $1;
		} elsif($loc =~ /\A$lws_rx($path_and_query_rx)$lws_rx\z/o) {
			# Illegal, but common and easy to handle sanely.
			my $pathquery = $1;
			$url =~ s/\A($http_prefix_rx[^\/]*).*\z/$1$pathquery/so;
		} else {
			_croak "redirection to malformed target";
		}
		exists $seen{$url} and _croak "redirection loop";
	}
	_croak "too many redirections";
}

=back

=head1 BUGS

IPv6 support is largely untested.  Reports of experiences with it would
be appreciated.

=head1 SEE ALSO

L<HTTP::Tiny>,
L<IO::Socket::IP>,
L<Net::FTP::Tiny>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
