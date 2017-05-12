use strict;
use warnings;
package Net::INET6Glue::FTP;
our $VERSION = 0.6;

############################################################################
# implement EPRT, EPSV for Net::FTP to support IPv6
############################################################################

use Net::INET6Glue::INET_is_INET6;
use Net::FTP; # tested with 2.77, 2.79
BEGIN {
    my %tested = map { $_ => 1 } qw(2.77 2.79);
    warn "Not tested with Net::FTP version $Net::FTP::VERSION" 
	if ! $tested{$Net::FTP::VERSION};
}   

use Socket;
use Carp 'croak';

if ( defined &Net::FTP::_EPRT ) {
    # Net::SSLGlue::FTP and Net::FTP 2.80 implement IPv6 too
    warn "somebody else already implements FTP IPv6 support - skipping ".
	__PACKAGE__."\n";

} else {
    # implement EPRT
    *Net::FTP::_EPRT = sub { 
	shift->command("EPRT", @_)->response() == Net::FTP::CMD_OK 
    };
    *Net::FTP::eprt = sub {
	@_ == 1 || @_ == 2 or croak 'usage: $ftp->eprt([PORT])';
	my ($ftp,$port) = @_;
	delete ${*$ftp}{net_ftp_intern_port};
	unless ($port) {
	    my $listen = ${*$ftp}{net_ftp_listen} ||= 
		$Net::INET6Glue::INET_is_INET6::INET6CLASS->new(
		    Listen    => 1,
		    Timeout   => $ftp->timeout,
		    LocalAddr => $ftp->sockhost,
		);
	    ${*$ftp}{net_ftp_intern_port} = 1;
	    my $fam = ($listen->sockdomain == AF_INET) ? 1:2;
	    $port = "|$fam|".$listen->sockhost."|".$listen->sockport."|";
	}
	my $ok = $ftp->_EPRT($port);
	${*$ftp}{net_ftp_port} = $port if $ok;
	return $ok;
    };

    # implement EPSV
    *Net::FTP::_EPSV = sub { 
	shift->command("EPSV", @_)->response() == Net::FTP::CMD_OK 
    };
    *Net::FTP::epsv = sub {
	my $ftp = shift;
	@_ and croak 'usage: $ftp->epsv()';
	delete ${*$ftp}{net_ftp_intern_port};

	$ftp->_EPSV && $ftp->message =~ m{\(([\x33-\x7e])\1\1(\d+)\1\)}
	    ? ${*$ftp}{'net_ftp_pasv'} = $2
	    : undef;
    };

    # redefine PORT and PASV so that they use EPRT and EPSV if necessary
    no warnings 'redefine';
    my $old_port = \&Net::FTP::port;
    *Net::FTP::port =sub {
	goto &$old_port if $_[0]->sockdomain == AF_INET or @_<1 or @_>2;
	goto &Net::FTP::eprt;
    };

    my $old_pasv = \&Net::FTP::pasv;
    *Net::FTP::pasv = sub {
	goto &$old_pasv if $_[0]->sockdomain == AF_INET or @_<1 or @_>2;
	goto &Net::FTP::epsv;
    };

    # redefined _dataconn to make use of the data it got from EPSV
    # copied and adapted from Net::FTP::_dataconn
    my $old_dataconn = \&Net::FTP::_dataconn;
    *Net::FTP::_dataconn = sub {
	goto &$old_dataconn if $_[0]->sockdomain == AF_INET;
	my $ftp = shift;

	my $pkg = "Net::FTP::" . $ftp->type;
	eval "require $pkg";
	$pkg =~ s/ /_/g;
	delete ${*$ftp}{net_ftp_dataconn};

	my $data;
	if ( my $port = ${*$ftp}{net_ftp_pasv} ) {
	    $data = $pkg->new(
		PeerAddr  => $ftp->peerhost,
		PeerPort  => $port,
		LocalAddr => ${*$ftp}{net_ftp_localaddr},
	    );
	} elsif (my $listen =  delete ${*$ftp}{net_ftp_listen}) {
	    $data = $listen->accept($pkg);
	    close($listen);
	}

	return if ! $data;

	$data->timeout($ftp->timeout);
	${*$ftp}{net_ftp_dataconn} = $data;
	${*$data} = "";
	${*$data}{net_ftp_cmd} = $ftp;
	${*$data}{net_ftp_blksize} = ${*$ftp}{net_ftp_blksize};
	return $data;
    };
}

1;

=head1 NAME

Net::INET6Glue::FTP - adds IPv6 support to L<Net::FTP> by hotpatching

=head1 SYNOPSIS

 use Net::INET6Glue::FTP;
 use Net::FTP;
 my $ftp = Net::FTP->new( '::1' );
 $ftp->login(...)

=head1 DESCRIPTION

This module adds support for IPv6 by hotpatching support for EPRT and EPSV
commands into L<Net::FTP> and hotpatching B<pasv>, B<port> and B<_dataconn>
methods to make use of EPRT and EPSV on IPv6 connections.

It also includes L<Net::INET6Glue::INET_is_INET6> to make the L<Net::FTP>
sockets IPv6 capable.

=head1 COPYRIGHT

This module is copyright (c) 2008..2014, Steffen Ullrich.
All Rights Reserved.
This module is free software. It may be used, redistributed and/or modified 
under the same terms as Perl itself.
