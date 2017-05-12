use strict;
use warnings;

package Net::IMP::Example::LogServerCertificate;
use base 'Net::IMP::Base';
use Net::SSLeay;

use fields (
    'done',    # done or no SSL
    'sbuf',    # buffer on server side
);

use Net::IMP qw(:log :DEFAULT); # import IMP_ constants
use Net::IMP::Debug;
use Carp 'croak';

sub INTERFACE {
    return ([
	undef,
	[ IMP_PASS, IMP_PREPASS, IMP_LOG ]
    ])
}


# create new analyzer object
sub new_analyzer {
    my ($factory,%args) = @_;
    my $self = $factory->SUPER::new_analyzer(%args);

    $self->run_callback(
	# we are not interested in data from client
	[ IMP_PASS, 0, IMP_MAXOFFSET ],
	# and we will not change data from server, only inspect
	[ IMP_PREPASS, 1, IMP_MAXOFFSET ],
    );

    $self->{sbuf} = '';
    return $self;
}

sub data {
    my ($self,$dir,$data) = @_;
    return if $dir == 0; # should not happen
    return if $self->{done}; # done or no SSL
    return if $data eq ''; # eof from server

    my $buf = $self->{sbuf} .= $data;

    if ( _read_ssl_handshake($self,\$buf,2)                  # Server Hello
	and my $certs = _read_ssl_handshake($self,\$buf,11)  # Certificates
    ) {
	$self->{done} = 1;

	my ($len) = unpack("xa3",substr($certs,0,4,''));
	$len = unpack("N","\0$len");
	substr($certs,$len) = '';
	$len = unpack("N","\0".substr($certs,0,3,''));
	substr($certs,$len) = '';
	my $i = 0;
	while ($certs ne '') {
	    my $clen = unpack("N","\0".substr($certs,0,3,''));
	    my $cert = substr($certs,0,$clen,'');
	    length($cert) == $clen or
		die "invalid certificate length ($clen vs. ".length($cert).")";
	    if ( my $line = eval { _cert2line($cert) } ) {
		$self->run_callback([ IMP_LOG,1,0,0,IMP_LOG_INFO,
		    sprintf("chain[%d]: %s",$i,$line)]);
	    } else {
		warn "failed to convert cert to string: $@";
	    }
	    $i++;
	}
    }

    $self->run_callback([ IMP_PASS,1,IMP_MAXOFFSET ])
	if $self->{done};
}

sub _cert2line {
    my $der = shift;
    my $bio = Net::SSLeay::BIO_new( Net::SSLeay::BIO_s_mem());
    Net::SSLeay::BIO_write($bio,$der);
    my $cert = Net::SSLeay::d2i_X509_bio($bio);
    Net::SSLeay::BIO_free($bio);
    $cert or die "cannot parse certificate: ".
	Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error());
    my $not_before = Net::SSLeay::X509_get_notBefore($cert);
    my $not_after = Net::SSLeay::X509_get_notAfter($cert);
    $_ = Net::SSLeay::P_ASN1_TIME_put2string($_) for($not_before,$not_after);
    my $subject = Net::SSLeay::X509_NAME_oneline(
	Net::SSLeay::X509_get_subject_name($cert));
    return "$subject | $not_before - $not_after";
}


sub _read_ssl_handshake {
    my ($self,$buf,$expect_htype) = @_;
    return if length($$buf) < 22; # need way more data

    my ($ctype,$version,$len,$htype) = unpack('CnnC',$$buf);
    if ($ctype != 22) {
	debug("no SSL >=3.0 handshake record");
	goto bad;
    } elsif ( $len > 2**14 ) {
	debug("length looks way too big - assuming no ssl");
	goto bad;
    } elsif ( $htype != $expect_htype ) {
	debug("unexpected handshake type $htype - assuming no ssl");
	goto bad;
    }

    length($$buf)-5 >= $len or return; # need more data
    substr($$buf,0,5,'');
    debug("got handshake type $htype length $len");
    return substr($$buf,0,$len,'');

    bad:
    $self->{done} = 1;
    return;
}


# debugging stuff
sub _hexdump {
    my ($buf,$len) = @_;
    $buf = substr($buf,0,$len) if $len;
    my @hx = map { sprintf("%02x",$_) } unpack('C*',$buf);
    my $t = '';
    while (@hx) {
	$t .= join(' ',splice(@hx,0,16))."\n";
    }
    return $t;
}


1;

__END__

=head1 NAME

Net::IMP::Example::LogServerCertificate - Proof Of Concept IMP plugin for
logging server certificate and chain of SSL connections

=head1 SYNOPSIS

    my $factory = Net::IMP::Example::LogServerCertificate->new_factory;

=head1 DESCRIPTION

C<Net::IMP::Example::LogServerCertificate> implements an analyzer, which expects
an SSL Server Hello on the server side, extracts the certificates and logs
information about them.
There are no further arguments.

=head1 BUGS

Sessions might be re-stablished with a session-id common between client and
server. In this case no certificates need to be exchanged and thus certificate
infos will not be tracked.
To work around it one might track session-ids and implement caching.

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT

Copyright by Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
