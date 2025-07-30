package Net::DNS::RR::DELEG;

use strict;
use warnings;
our $VERSION = (qw$Id: DELEG.pm 2033 2025-07-29 18:03:07Z willem $)[2];

use base qw(Net::DNS::RR::SVCB);


=head1 NAME

Net::DNS::RR::DELEG - DNS DELEG resource record

=cut

use integer;

my %keyname = reverse(
	alpn		       => 'key1',			# RFC9460(7.1)
	'no-default-alpn'      => 'key2',			# RFC9460(7.1)
	port		       => 'key3',			# RFC9460(7.2)
	IPv4		       => 'key4',
	IPv6		       => 'key6',
	dohpath		       => 'key7',			# RFC9461
	'tls-supported-groups' => 'key9',
	);


sub _format_rdata {			## format rdata portion of RR string.
	my $self = shift;

	my $priority = $self->{SvcPriority};
	my @target   = grep { $_ ne '.' } $self->{TargetName}->string;
	my $mode     = $priority ? 'DIRECT' : 'INCLUDE';
	my @rdata    = join '=', $mode, @target;
	push @rdata, "priority=$priority" if $priority > 1;

	my $params = $self->{SvcParams} || [];
	my @params = @$params;
	while (@params) {
		my $key = join '', 'key', shift @params;
		my $val = shift @params;
		if ( my $name = $keyname{$key} ) {
			my @val = grep {length} $self->$name;
			my @rhs = @val ? join ',', @val : @val;
			push @rdata, join '=', $name, @rhs;
		} else {
			my @hex = unpack 'H*', $val;
			$self->_annotation(qq(unexpected $key="@hex"));
		}
	}

	return @rdata;
}


sub _parse_rdata {			## populate RR from rdata in argument list
	my ( $self, @argument ) = @_;

	while ( local $_ = shift @argument ) {
		my @value;
		m/^[^=]+=?(.*)$/;
		for ( my $rhs = /=$/ ? shift @argument : $1 ) {
			s/^"(.*)"$/$1/;				# strip enclosing quotes
			s/\\,/\\044/g;				# disguise escaped comma
			push @value, length() ? split /,/ : '';
		}

		s/[-]/_/g;					# extract identifier
		m/^([^=]+)/;
		$self->$1(@value);
	}
	return;
}


sub _post_parse {			## parser post processing
	my $self = shift;

	my $paramref = $self->{SvcParams} || [];
	unless (@$paramref) {
		return if $self->_empty;
		die('no name or address specified') unless $self->targetname;
	}
	$self->SUPER::_post_parse;
	return;
}


sub _defaults {				## specify RR attribute default values
	my $self = shift;

	$self->DIRECT;
	return;
}


sub DIRECT {
	my ( $self, @servername ) = @_;
	$self->targetname( @servername, '.' );
	return $self->SvcPriority(1);
}

sub INCLUDE {
	my ( $self, $target ) = @_;
	$self->targetname($target);
	return $self->SvcPriority(0);
}

sub priority {
	my ( $self, @value ) = @_;
	my $priority = $self->{SvcPriority};
	return $priority unless @value;
	my ($value) = @value;
	if ($priority) {
		die 'invalid zero priority' unless $value;
	} else {
		die 'invalid non-zero priority' if $value;
	}
	return $self->SvcPriority(@value);
}

sub targetname {
	my ( $self, @value ) = @_;
	$self->{TargetName} = Net::DNS::DomainName->new(@value) if @value;
	my $target = $self->{TargetName} ? $self->{TargetName}->name : return;
	return $target eq '.' ? undef : $target;
}

sub ipv4 {				## IPv4=192.0.2.53,...
	my ( $self, @value ) = @_;
	my $packed = $self->_SvcParam( 4, _ipv4(@value) );
	return $packed if @value;
	my @ip = unpack 'a4' x ( length($packed) / 4 ), $packed;
	return map { bless( {address => $_}, 'Net::DNS::RR::A' )->address } @ip;
}

sub ipv6 {				## IPv6=2001:DB8::53,...
	my ( $self, @value ) = @_;
	my $packed = $self->_SvcParam( 6, _ipv6(@value) );
	return $packed if @value;
	my @ip = unpack 'a16' x ( length($packed) / 16 ), $packed;
	return map { bless( {address => $_}, 'Net::DNS::RR::AAAA' )->address_short } @ip;
}

sub port {				## port=53
	my ( $self, @value ) = @_;
	my $packed = $self->_SvcParam( 3, map { _integer16($_) } @value );
	return @value ? $packed : unpack 'n', $packed;
}

sub alpn {				## alpn=dot,doq
	my ( $self, @value ) = @_;
	my $packed = $self->_SvcParam( 1, _string(@value) );
	return $packed if @value;
	my $index = 0;
	while ( $index < length $packed ) {
		( my $text, $index ) = Net::DNS::Text->decode( \$packed, $index );
		push @value, $text->string;
	}
	return @value;
}

sub tls_supported_groups {		## tls_supported_groups=29,23
	my ( $self, @value ) = @_;				# uncoverable pod
	my $packed = $self->_SvcParam( 9, _integer16(@value) );
	return @value ? $packed : unpack 'n*', $packed;
}


sub generic {
	my $self  = shift;
	my @ttl	  = grep {defined} $self->{ttl};
	my @class = map	 { $_ ? "CLASS$_" : () } $self->{class};
	my @core  = ( $self->{owner}->string, @ttl, @class, "TYPE$self->{type}" );
	my @rdata = $self->_empty ? () : $self->SUPER::_format_rdata;
	return join "\n\t", Net::DNS::RR::_wrap( "@core (", @rdata, ')' );
}


########################################

sub _concatenate {			## concatenate octet string(s)
	my @arg = @_;
	return scalar(@arg) ? join( '', @arg ) : return @arg;
}

sub _ipv4 {
	my @arg = @_;
	return _concatenate( map { Net::DNS::RR::A::address( {}, $_ ) } @arg );
}

sub _ipv6 {
	my @arg = @_;
	return _concatenate( map { Net::DNS::RR::AAAA::address( {}, $_ ) } @arg );
}

sub _integer16 {
	my @arg = @_;
	return _concatenate( map { pack( 'n', $_ ) } @arg );
}

sub _string {
	my @arg = @_;
	return _concatenate( map { Net::DNS::Text->new($_)->encode() } @arg );
}

########################################


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('zone DELEG DIRECT=nameserver IPv4=192.0.2.1');
	$rr = Net::DNS::RR->new('zone DELEG DIRECT IPv6=2001:db8::53');
	$rr = Net::DNS::RR->new('zone DELEG INCLUDE=targetname');

=head1 DESCRIPTION


The DNS DELEG resource record set, wherever it appears, advertises the
authoritative nameservers and transport parameters to be used to resolve
queries for data at the owner name or any subordinate thereof.

The DELEG RRset is authoritative data within the delegating zone
and must not appear at the apex of the subordinate zone.

The DELEG class is derived from, and inherits properties of,
the Net::DNS::RR::SVCB class.


=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 DIRECT

	example. DELEG DIRECT=nameserver
	example. DELEG DIRECT=nameserver IPv6=2001:db8::53
	example. DELEG DIRECT IPv4=192.0.2.1 IPv6=2001:db8::53
	$nameserver = $rr->targetname;

Specifies the nameserver domain name, which may be absent,
and sets DIRECT mode (non-zero SvcPriority).


=head2 INCLUDE

	example. DELEG INCLUDE=targetname
	$targetname = $rr->targetname;

Specifies the location of an external nameserver configuration
and sets INCLUDE mode (zero SvcPriority).


=head2 priority

	example. DELEG DIRECT=nameserver priority=123
	$priority = $rr->priority;

Gets or sets the priority value for the DELEG record.
An exception will be raised for any attempt to set
a non-zero priority for INCLUDE.


=head2 targetname

	$target = $rr->targetname;

Returns the target domain name or the undefined value if not specified.


=head2 IPv4, ipv4

	example. DELEG DIRECT IPv4=192.0.2.1
	@ip = $rr->IPv4;

Sets or gets the list of IP addresses.

=head2 IPv6, ipv6

	example. DELEG DIRECT IPv6=2001:db8::53
	@ip = $rr->IPv6;

Sets or gets the list of IP addresses.


=head1 COPYRIGHT

Copyright (c)2025 Dick Franks. 

All rights reserved.

Package template (c)2009,2012 O.M.Kolkman and R.W.Franks.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<perl> L<Net::DNS> L<Net::DNS::RR>
L<Net::DNS::RR::SVCB>

draft-ietf-deleg

L<RFC9460|https://iana.org/go/rfc9460>

L<Service Parameter Keys|https://iana.org/assignments/dns-svcb>

=cut
