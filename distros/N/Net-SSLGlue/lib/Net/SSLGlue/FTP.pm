
package Net::SSLGlue::FTP;

use strict;
use warnings;
use Carp 'croak';
use IO::Socket::SSL '$SSL_ERROR';
use Net::SSLGlue::Socket;
use Socket 'AF_INET';

our $VERSION = 1.002;

BEGIN {
    require Net::FTP;
    if (defined &Net::FTP::starttls) {
	warn "using SSL support of Net::FTP $Net::FTP::VERSION instead of SSLGlue";
	goto DONE;
    }

    $Net::FTP::VERSION eq '2.77'
	or warn "Not tested with Net::FTP version $Net::FTP::VERSION";

    require Net::FTP::dataconn;
    for my $class (qw(Net::FTP Net::FTP::dataconn)) {
	no strict 'refs';
	my $fixed;
	for( @{ "${class}::ISA" } ) {
	    $_ eq 'IO::Socket::INET' or next;
	    $_ = 'Net::SSLGlue::Socket';
	    $fixed = 1;
	    last;
	}
	die "cannot replace IO::Socket::INET with Net::SSLGlue::Socket in ${class}::ISA"
	    if ! $fixed;
    }

    # redefine Net::FTP::new so that it understands SSL => 1 and connects directly
    # with SSL to the server
    no warnings 'redefine';
    my $onew = Net::FTP->can('new');
    *Net::FTP::new = sub {
	my $class = shift;
	my %args = @_%2 ? ( Host => shift(), @_ ): @_;
	my %sslargs = map { $_ => delete $args{$_} }
	    grep { m{^SSL_} } keys %args;

	my $self;
	if ( $args{SSL} ) {
	    # go immediatly to SSL
	    # Net::FTP::new gives only specific args to socket class
	    $args{Port} ||= 990;
	    local %Net::SSLGlue::Socket::ARGS = ( SSL => 1, %sslargs );
	    $self = $onew->($class,%args) or return;
	    ${*$self}{net_ftp_tlstype} = 'P';
	} else {
	    $self = $onew->($class,%args) or return;
	}
	${*$self}{net_ftp_tlsargs} = \%sslargs;
	return $self;
    };

    # add starttls method to upgrade connection to SSL: AUTH TLS
    *Net::FTP::starttls = sub {
	my $self = shift;
	$self->is_ssl and croak("called starttls within SSL session");
	$self->_AUTH('TLS') == &Net::FTP::CMD_OK or return;

	my $host = $self->host;
	# for name verification strip port from domain:port, ipv4:port, [ipv6]:port
	$host =~s{(?<!:):\d+$}{};

	my %args = (
	    SSL_verify_mode => 1,
	    SSL_verifycn_scheme => 'ftp',
	    SSL_verifycn_name => $host,
	    # reuse SSL session of control connection in data connections
	    SSL_session_cache => Net::SSLGlue::FTP::SingleSessionCache->new,
	    %{ ${*$self}{net_ftp_tlsargs}},
	    @_
	);

	$self->start_SSL(%args) or return;
	${*$self}{net_ftp_tlsargs} = \%args;
	$self->prot('P');
	return 1;
    };

    # add prot method to set protection level (PROT C|P)
    *Net::FTP::prot = sub {
	my ($self,$type) = @_;
	$type eq 'C' or $type eq 'P' or croak("type must by C or P");
	$self->_PBSZ(0) or return;
	$self->_PROT($type) or return;
	${*$self}{net_ftp_tlstype} = $type;
	return 1;
    };

    # add stoptls method to downgrade connection from SSL: CCC
    *Net::FTP::stoptls = sub {
	my $self = shift;
	$self->is_ssl or croak("called stoptls outside SSL session");
	$self->_CCC() or return;
	$self->stop_SSL();
	return 1;
    };

    # add EPSV for new style passive mode (incl. IPv6)
    *Net::FTP::epsv = sub {
	my $self = shift;
	@_ and croak 'usage: $ftp->epsv()';
	delete ${*$self}{net_ftp_intern_port};

	$self->_EPSV && $self->message =~ m{\(([\x33-\x7e])\1\1(\d+)\1\)}
	    ? ${*$self}{'net_ftp_pasv'} = [ $self->peerhost, $2 ]
	    : undef;
    };

    # redefine PASV so that it uses EPSV on IPv6
    # also net_ftp_pasv contains now the parsed [ip,port]
    *Net::FTP::pasv = sub {
	my $self = shift;
	@_ and croak 'usage: $ftp->port()';
	return $self->epsv if $self->sockdomain != AF_INET;
	delete ${*$self}{net_ftp_intern_port};

	if ( $self->_PASV &&
	    $self->message =~ m{(\d+,\d+,\d+,\d+),(\d+),(\d+)} ) {
	    my $port = 256 * $2 + $3;
	    ( my $ip = $1 ) =~s{,}{.}g;
	    return ${*$self}{'net_ftp_pasv'} = [ $ip,$port ];
	}
	return;
    };

    # add EPRT for new style passive mode (incl. IPv6)
    *Net::FTP::eprt = sub {
	@_ == 1 || @_ == 2 or croak 'usage: $self->eprt([PORT])';
	return _eprt('EPRT',@_);
    };

    # redefine PORT to use EPRT for IPv6
    *Net::FTP::port = sub {
	@_ == 1 || @_ == 2 or croak 'usage: $self->port([PORT])';
	return _eprt('PORT',@_);
    };

    sub _eprt {
	my ($cmd,$self,$port) = @_;
	delete ${*$self}{net_ftp_intern_port};
	unless ($port) {
	    my $listen = ${*$self}{net_ftp_listen} ||= Net::SSLGlue::Socket->new(
		Listen    => 1,
		Timeout   => $self->timeout,
		LocalAddr => $self->sockhost,
	    );
	    ${*$self}{net_ftp_intern_port} = 1;
	    my $fam = ($listen->sockdomain == AF_INET) ? 1:2;
	    if ( $cmd eq 'EPRT' || $fam == 2 ) {
		$port = "|$fam|".$listen->sockhost."|".$listen->sockport."|";
		$cmd = 'EPRT';
	    } else {
		my $p = $listen->sockport;
		$port = join(',',split(m{\.},$listen->sockhost),$p >> 8,$p & 0xff);
	    }
	}
	my $ok = $cmd eq 'EPRT' ? $self->_EPRT($port) : $self->_PORT($port);
	${*$self}{net_ftp_port} = $port if $ok;
	return $ok;
    }



    for my $cmd (qw(PBSZ PROT CCC EPRT EPSV)) {
	no strict 'refs';
	*{"Net::FTP::_$cmd"} = sub {
	    shift->command("$cmd @_")->response() == &Net::FTP::CMD_OK
	}
    }


    # redefine _dataconn to
    # - support IPv6
    # - upgrade data connection to SSL if PROT P
    *Net::FTP::_dataconn = sub {
	my $self = shift;
	my $pkg = "Net::FTP::" . $self->type;
	eval "require $pkg";
	$pkg =~ s/ /_/g;
	delete ${*$self}{net_ftp_dataconn};

	my $conn;
	if ( my $pasv = ${*$self}{net_ftp_pasv} ) {
	    $conn = $pkg->new(
		PeerAddr  => $pasv->[0],
		PeerPort  => $pasv->[1],
		LocalAddr => ${*$self}{net_ftp_localaddr},
	    ) or return;
	} elsif (my $listen =  delete ${*$self}{net_ftp_listen}) {
	    $conn = $listen->accept($pkg) or return;
	    close($listen);
	}

	if (( ${*$self}{net_ftp_tlstype} || '') eq 'P'
	    && ! $conn->start_SSL( $self->is_ssl ? ( 
		    SSL_reuse_ctx => $self, 
		    SSL_verifycn_name => ${*$self}{net_ftp_tlsargs}->{SSL_verifycn_name} 
		):( 
		    %{${*$self}{net_ftp_tlsargs}} 
		)
	    )) {
	    croak("failed to ssl upgrade dataconn: $SSL_ERROR");
	    return;
	}

	$conn->timeout($self->timeout);
	${*$self}{net_ftp_dataconn} = $conn;
	${*$conn} = "";
	${*$conn}{net_ftp_cmd} = $self;
	${*$conn}{net_ftp_blksize} = ${*$self}{net_ftp_blksize};
	return $conn;
    };

    DONE:
    1;
}

{
    # Session Cache with single entry
    # used to make sure that we reuse same session for control channel and data
    package Net::SSLGlue::FTP::SingleSessionCache;
    sub new { my $x; return bless \$x,shift }
    sub add_session {
	my ($self,$key,$session) = @_;
	Net::SSLeay::SESSION_free($$self) if $$self;
	$$self = $session;
    }
    sub get_session {
	my $self = shift;
	return $$self
    }
    sub DESTROY {
	my $self = shift;
	Net::SSLeay::SESSION_free($$self) if $$self;
    }
}

1;

=head1 NAME

Net::SSLGlue::FTP - extend Net::FTP for FTPS (SSL) and IPv6

=head1 SYNOPSIS

    use Net::SSLGlue::FTP;
    # SSL right from start
    my $ftps = Net::FTP->new( $host,
	SSL => 1,
	SSL_ca_path => ...
    );

    # SSL through upgrade of plain connection
    my $ftp = Net::FTP->new( $host );
    $ftp->starttls( SSL_ca_path => ... );

    # change protection mode to unencrypted|encrypted
    $ftp->prot('C'); # clear
    $ftp->prot('P'); # protected

=head1 DESCRIPTION

L<Net::SSLGlue::FTP> extends L<Net::FTP> so one can either start directly with
SSL or switch later to SSL using starttls method (AUTH TLS command).
If IO::Socket::IP or IO::Socket::INET6 are installed it will also transparently
use IPv6.

By default it will take care to verify the certificate according to the rules
for FTP implemented in L<IO::Socket::SSL>.

=head1 METHODS

=over 4

=item new

The method C<new> of L<Net::FTP> is now able to start directly with SSL when
the argument C<<SSL => 1>> is given. One can give the usual C<SSL_*> parameter
of L<IO::Socket::SSL> to C<Net::FTP::new>.

=item starttls

If the connection is not yet SSLified it will issue the "AUTH TLS" command and
change the object, so that SSL will now be used.

=item peer_certificate ...

Once the SSL connection is established you can use this method to get
information about the certificate. See the L<IO::Socket::SSL> documentation.

=back

All of these methods can take the C<SSL_*> parameter from L<IO::Socket::SSL> to
change the behavior of the SSL connection. The following parameters are
especially useful:

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

=head1 SEE ALSO

IO::Socket::SSL, Net::FTP, Net::SSLGlue::Socket

=head1 COPYRIGHT

This module is copyright (c) 2013, Steffen Ullrich.
All Rights Reserved.
This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.
