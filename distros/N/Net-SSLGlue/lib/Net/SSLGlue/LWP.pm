use strict;
use warnings;
package Net::SSLGlue::LWP;
our $VERSION = 0.501;
use LWP::UserAgent '5.822';
use IO::Socket::SSL 1.19;
use URI;

# force Net::SSLGlue::LWP::Socket as superclass of Net::HTTPS, because
# only it can verify certificates
my $use_existent;
BEGIN {
    require LWP::Protocol::https;
    $use_existent = $LWP::Protocol::https::VERSION
	&& $LWP::Protocol::https::VERSION >= 6.06
	&& $LWP::UserAgent::VERSION >= 6.06;
    if ($use_existent) {
	my $oc = $Net::HTTPS::SSL_SOCKET_CLASS ||
	    $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS};
	$use_existent = 0 if $oc && $oc ne 'IO::Socket::SSL';
    }
    if ($use_existent) {
	warn "Your LWP::UserAgent/LWP::Protocol::https looks fine.\n".
	    "Will use it instead of Net::SSLGLue::LWP\n";
    } else {
	my $oc = $Net::HTTPS::SSL_SOCKET_CLASS;
	$Net::HTTPS::SSL_SOCKET_CLASS = my $need = 'Net::SSLGlue::LWP::Socket';
	require Net::HTTPS;

	if ( ( my $oc = $Net::HTTPS::SSL_SOCKET_CLASS ) ne $need ) {
	    # was probably loaded before, change ISA
	    grep { s{^\Q$oc\E$}{$need} } @Net::HTTPS::ISA
	}
	die "cannot force $need into Net::HTTPS"
	    if $Net::HTTPS::SSL_SOCKET_CLASS ne $need;
    }
}


our %SSLopts;  # set by local and import
sub import {
    shift;
    %SSLopts = @_;
}

if (!$use_existent) {
    # add SSL options
    my $old_eso = UNIVERSAL::can( 'LWP::Protocol::https','_extra_sock_opts' );
    no warnings 'redefine';
    *LWP::Protocol::https::_extra_sock_opts = sub {
	return (
	    $old_eso ? ( $old_eso->(@_) ):(),
	    SSL_verify_mode => 1,
	    SSL_verifycn_scheme => 'http',
	    HTTPS_proxy => $_[0]->{ua}{https_proxy},
	    %SSLopts,
	);
    };

    # fix https_proxy handling - forward it to a variable handled by me
    my $old_proxy = defined &LWP::UserAgent::proxy && \&LWP::UserAgent::proxy
	or die "cannot find LWP::UserAgent::proxy";
    *LWP::UserAgent::proxy = sub {
	my ($self,$key,$val) = @_;
	goto &$old_proxy if ref($key) || $key ne 'https';
	if (@_>2) {
	    my $rv = &$old_proxy;
	    $self->{https_proxy} = delete $self->{proxy}{https}
		|| die "https proxy not set?";
	}
	return $self->{https_proxy};
    };

} else {
    # wrapper around LWP::Protocol::https::_extra_sock_opts to support %SSLopts
    my $old_eso = UNIVERSAL::can( 'LWP::Protocol::https','_extra_sock_opts' )
	or die "no LWP::Protocol::https::_extra_sock_opts found";
    no warnings 'redefine';
    *LWP::Protocol::https::_extra_sock_opts = sub {
	return (
	    $old_eso->(@_),
	    %SSLopts,
	);
    };
}

{

    package Net::SSLGlue::LWP::Socket;
    use IO::Socket::SSL;
    use base 'IO::Socket::SSL';
    my $sockclass = 'IO::Socket::INET';
    use URI::Escape 'uri_unescape';
    use MIME::Base64 'encode_base64';
    $sockclass .= '6' if eval "require IO::Socket::INET6";

    sub configure {
	my ($self,$args) = @_;
	my $phost = delete $args->{HTTPS_proxy}
	    or return $self->SUPER::configure($args);
	$phost = URI->new($phost) if ! ref $phost;

	my $port = $args->{PeerPort};
	my $host = $args->{PeerHost} || $args->{PeerAddr};
	if ( ! $port ) {
	    $host =~s{:(\w+)$}{};
	    $port = $args->{PeerPort} = $1;
	    $args->{PeerHost} = $host;
	}
	if ( $phost->scheme ne 'http' ) {
	    $@ = "scheme ".$phost->scheme." not supported for https_proxy";
	    return;
	}
	my $auth = '';
	if ( my ($user,$pass) = split( ':', $phost->userinfo || '' ) ) {
	    $auth = "Proxy-authorization: Basic ".
		encode_base64( uri_unescape($user).':'.uri_unescape($pass),'' ).
		"\r\n";
	}

	my $pport = $phost->port;
	$phost = $phost->host;

	# temporally downgrade $self so that the right connect chain
	# gets called w/o doing SSL stuff. If we don't do it it will
	# try to call IO::Socket::SSL::connect
	my $ssl_class = ref($self);
	bless $self,$sockclass;
	$self->configure({ %$args, PeerAddr => $phost, PeerPort => $pport }) or do {
	    $@ = "connect to proxy $phost port $pport failed";
	    return;
	};
	print $self "CONNECT $host:$port HTTP/1.0\r\n$auth\r\n";
	my $hdr = '';
	while (<$self>) {
	    $hdr .= $_;
	    last if $_ eq "\n" or $_ eq "\r\n";
	}
	if ( $hdr !~m{\AHTTP/1.\d 2\d\d} ) {
	    # error
	    $@ = "non 2xx response to CONNECT: $hdr";
	    return;
	}

	# and upgrade self by calling start_SSL
	$ssl_class->start_SSL( $self,
	    SSL_verifycn_name => $host,
	    %$args
	) or do {
	    $@ = "start SSL failed: $SSL_ERROR";
	    return;
	};
	return $self;
    };
}

1;

=head1 NAME

Net::SSLGlue::LWP - proper certificate checking for https in LWP

=head1 SYNOPSIS
u
    use Net::SSLGlue::LWP SSL_ca_path => ...;
    use LWP::Simple;
    get( 'https://www....' );

    {
	local %Net::SSLGlue::LWP::SSLopts = %Net::SSLGlue::LWP::SSLopts;

	# switch off verification
	$Net::SSLGlue::LWP::SSLopts{SSL_verify_mode} = 0;

	# or: set different verification policy, because cert does
	# not conform to RFC (wildcards in CN are not allowed for https,
	# but some servers do it anyway)
	$Net::SSLGlue::LWP::SSLopts{SSL_verifycn_scheme} = {
	    wildcards_in_cn => 'anywhere',
	    check_cn => 'always',
	};
    }


=head1 DESCRIPTION

L<Net::SSLGlue::LWP> modifies L<Net::HTTPS> and L<LWP::Protocol::https> so that
L<Net::HTTPS> is forced to use L<IO::Socket::SSL> instead of L<Crypt::SSLeay>,
and that L<LWP::Protocol::https> does proper certificate checking using the
C<http> SSL_verify_scheme from L<IO::Socket::SSL>.

This module should only be used for older LWP version, see B<Supported LWP
versions> below.

Because L<LWP> does not have a mechanism to forward arbitrary parameters for
the construction of the underlying socket these parameters can be set globally
when including the package, or with local settings of the
C<%Net::SSLGlue::LWP::SSLopts> variable.

All of the C<SSL_*> parameter from L<IO::Socket::SSL> can be used; the
following parameters are especially useful:

=over 4

=item SSL_ca_path, SSL_ca_file

Specifies the path or a file where the CAs used for checking the certificates
are located. This is typically L</etc/ssl/certs> on UNIX systems.

=item SSL_verify_mode

If set to 0, verification of the certificate will be disabled. By default
it is set to 1 which means that the peer certificate is checked.

=item SSL_verifycn_name

Usually the name given as the hostname in the constructor is used to verify the
identity of the certificate. If you want to check the certificate against
another name you can specify it with this parameter.

=back

=head1 Supported LWP versions

This module should be used for older LWP version only. Starting with version
6.06 it is recommended to use LWP directly. If a recent version is found
Net::SSLGlue::LWP will print out a warning and not monkey patch too much into
LWP (only as much as necessary to still support C<%Net::SSLGlue::LWP::SSLopts>).

=head1 SEE ALSO

IO::Socket::SSL, LWP, Net::HTTPS, LWP::Protocol::https

=head1 COPYRIGHT

This module is copyright (c) 2008..2015, Steffen Ullrich.
All Rights Reserved.
This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

