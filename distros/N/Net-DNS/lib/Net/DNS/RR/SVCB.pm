package Net::DNS::RR::SVCB;

use strict;
use warnings;
our $VERSION = (qw$Id: SVCB.pm 2018 2025-07-01 11:57:43Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::SVCB - DNS SVCB resource record

=cut

use integer;

use Net::DNS::DomainName;
use Net::DNS::RR::A;
use Net::DNS::RR::AAAA;
use Net::DNS::Text;
use MIME::Base64;


my %keybyname = (
	mandatory	       => 'key0',			# RFC9460(8)
	alpn		       => 'key1',			# RFC9460(7.1)
	'no-default-alpn'      => 'key2',			# RFC9460(7.1)
	port		       => 'key3',			# RFC9460(7.2)
	ipv4hint	       => 'key4',			# RFC9460(7.3)
	ech		       => 'key5',			# RFC9460
	ipv6hint	       => 'key6',			# RFC9460(7.3)
	dohpath		       => 'key7',			# RFC9461
	ohttp		       => 'key8',			# RFC9540(4)
	'tls-supported-groups' => 'key9',
	);


sub _decode_rdata {			## decode rdata from wire-format octet string
	my ( $self, $data, $offset ) = @_;

	my $limit = $self->{rdlength};
	my $rdata = $self->{rdata} = substr $$data, $offset, $limit;
	$self->{SvcPriority} = unpack 'n', $rdata;
	( $self->{TargetName}, $offset ) = Net::DNS::DomainName->decode( \$rdata, 2 );

	my $params = $self->{SvcParams} = [];
	while ( ( my $start = $offset + 4 ) <= $limit ) {
		my ( $key, $size ) = unpack( "\@$offset n2", $rdata );
		my $next = $start + $size;
		last if $next > $limit;
		push @$params, ( $key, substr $rdata, $start, $size );
		$offset = $next;
	}
	die $self->type . ': corrupt RDATA' unless $offset == $limit;
	return;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my $self = shift;

	return $self->{rdata} if $self->{rdata};
	my @packed = pack 'n a*', $self->{SvcPriority}, $self->{TargetName}->encode;
	my $params = $self->{SvcParams} || [];
	my @params = @$params;
	while (@params) {
		my $key = shift @params;
		my $val = shift @params;
		push @packed, pack( 'n2a*', $key, length($val), $val );
	}
	return join '', @packed;
}


sub _format_rdata {			## format rdata portion of RR string.
	my $self = shift;

	my @rdata = unpack 'H4', pack 'n', $self->{SvcPriority};

	my $encode = $self->{TargetName}->encode();
	my $length = 2 + length $encode;
	my @target = grep {length} split /(\S{32})/, unpack 'H*', $encode;
	my $target = substr $self->{TargetName}->string, 0, 40;
	push @rdata, join '', shift(@target), "\t; $target\n";
	push @rdata, @target;

	my $params = $self->{SvcParams} || [];
	my @params = @$params;
	while (@params) {
		my $key = shift @params;
		my $val = shift @params;
		push @rdata, "\n", unpack 'H4H4', pack( 'n2', $key, length $val );
		my @hex = grep {length} split /(\S{32})/, unpack 'H*', $val;
		push @rdata, shift @hex if @hex;
		push @rdata, "\t; key$key\n" unless $key < 16;
		push @rdata, @hex;
		$length += 4 + length $val;
	}
	if ( $self->{rdata} ) {
		if ( my $corrupt = substr $self->{rdata}, $length ) {
			my ( $hex, @hex ) = grep {length} split /(\S{32})/, unpack 'H*', $corrupt;
			push @rdata, "\n$hex\t; corrupt RDATA\n", @hex;
			$length += length $corrupt;
		}
	}
	return ( "\\# $length", @rdata );
}


sub _parse_rdata {			## populate RR from rdata in argument list
	my ( $self, @argument ) = @_;

	$self->svcpriority( shift @argument );
	$self->targetname( shift @argument );

	local $SIG{__WARN__} = sub { die @_ };
	while ( my $svcparam = shift @argument ) {
		for ($svcparam) {
			my @value;
			if (/^key\d+$/i) {
				push @value, '';
			} elsif (/^key\d+=(.*)$/i) {
				local $_ = length($1) ? $1 : shift @argument;
				s/^"([^"]*)"$/$1/;		# strip enclosing quotes
				push @value, $_;
			} elsif (/^[^=]+=(.*)$/) {
				local $_ = length($1) ? $1 : shift @argument;
				die <<"Amen" if /\\092[,\\]/;
SVCB:	Please use standard RFC1035 escapes
	RFC9460 double-escape insanity not implemented
Amen
				s/^"([^"]*)"$/$1/;		# strip enclosing quotes
				s/\\,/\\044/g;			# disguise (RFC1035) escaped comma
				push @value, split /,/;
			}

			s/[-]/_/g;				# extract identifier
			m/^([^=]+)/;
			$self->$1(@value);
		}
	}
	return;
}


sub _post_parse {			## parser post processing
	my $self = shift;

	my $paramref = $self->{SvcParams} || [];
	my %svcparam = scalar(@$paramref) ? @$paramref : return;

	$self->key0(undef);					# ruse to force sorting of SvcParams
	if ( defined $svcparam{0} ) {
		my %unique;
		foreach ( grep { !$unique{$_}++ } unpack 'n*', $svcparam{0} ) {
			die( $self->type . qq[: unexpected "key0" in mandatory list] ) if $unique{0};
			die( $self->type . qq[: duplicate "key$_" in mandatory list] ) if --$unique{$_};
			die( $self->type . qq[: mandatory "key$_" not present] ) unless defined $svcparam{$_};
		}
		$self->mandatory( keys %unique );		# restore mandatory key list
	}
	die( $self->type . qq[: expected alpn="..." not present] ) if defined( $svcparam{2} ) && !$svcparam{1};
	return;
}


sub _defaults {				## specify RR attribute default values
	my $self = shift;

	$self->_parse_rdata(qw(0 .));
	return;
}


sub svcpriority {
	my ( $self, @value ) = @_;				# uncoverable pod
	for (@value) { $self->{SvcPriority} = 0 + $_ }
	return $self->{SvcPriority} || 0;
}


sub targetname {
	my ( $self, @value ) = @_;				# uncoverable pod

	for (@value) { $self->{TargetName} = Net::DNS::DomainName->new($_) }

	my $target = $self->{TargetName} ? $self->{TargetName}->name : return;
	return $target unless $self->{SvcPriority};
	return ( $target eq '.' ) ? $self->owner : $target;
}


sub mandatory {				## mandatory=key1,port,...
	my ( $self, @value ) = @_;
	my @list = map { $keybyname{lc $_} || $_ } map { split /,/ } @value;
	my @keys = map { /(\d+)$/ ? $1 : die( $self->type . qq[: unexpected "$_"] ) } @list;
	return $self->key0( _integer16( sort { $a <=> $b } @keys ) );
}

sub alpn {				## alpn=h3,h2,...
	my ( $self, @value ) = @_;
	return $self->key1( _string(@value) );
}

sub no_default_alpn {			## no-default-alpn	(Boolean)
	my ( $self, @value ) = @_;				# uncoverable pod
	return $self->key2() if defined wantarray;
	return $self->key2( _boolean(@value) );
}

sub port {				## port=1234
	my ( $self, @value ) = @_;
	return $self->key3( map { _integer16($_) } @value );
}

sub ipv4hint {				## ipv4hint=192.0.2.1,...
	my ( $self, @value ) = @_;
	return $self->key4( _ipv4(@value) );
}

sub ech {				## ech=base64
	my ( $self, @value ) = @_;
	return $self->key5( map { _base64($_) } @value );
}

sub ipv6hint {				## ipv6hint=2001:DB8::1,...
	my ( $self, @value ) = @_;
	return $self->key6( _ipv6(@value) );
}

sub dohpath {				## dohpath=/dns-query{?dns}
	my ( $self, @value ) = @_;				# uncoverable pod
	return $self->key7(@value);
}

sub ohttp {				## ohttp
	my ( $self, @value ) = @_;				# uncoverable pod
	return $self->key8() if defined wantarray;
	return $self->key8( _boolean(@value) );
}

sub tls_supported_groups {		## tls_supported_groups=29,23
	my ( $self, @value ) = @_;				# uncoverable pod
	return $self->key9( _integer16(@value) );
}


########################################


sub _presentation {			## represent octet string(s) using local charset
	my @arg = @_;
	my $raw = scalar(@arg) ? join( '', @arg ) : return ();	# concatenate arguments
	return Net::DNS::Text->decode( \$raw, 0, length($raw) )->string;
}

sub _boolean {
	my @arg = @_;
	return '' unless scalar @arg;
	return shift(@arg) ? '' : undef;
}

sub _string {
	my @arg = @_;
	return _presentation( map { Net::DNS::Text->new($_)->encode() } @arg );
}

sub _base64 {
	my @arg = @_;
	return _presentation( map { MIME::Base64::decode($_) } @arg );
}

sub _integer16 {
	my @arg = @_;
	return _presentation( map { pack( 'n', $_ ) } @arg );
}

sub _ipv4 {
	my @arg = @_;
	return _presentation( map { Net::DNS::RR::A::address( {}, $_ ) } @arg );
}

sub _ipv6 {
	my @arg = @_;
	return _presentation( map { Net::DNS::RR::AAAA::address( {}, $_ ) } @arg );
}


sub AUTOLOAD {				## Dynamic constructor/accessor methods
	my ( $self, @argument ) = @_;

	our $AUTOLOAD;
	my ($method)  = reverse split /::/, $AUTOLOAD;
	my $canonical = lc($method);
	$canonical =~ s/-/_/g;
	if ( $self->can($canonical) ) {
		no strict 'refs';	## no critic ProhibitNoStrict
		*{$AUTOLOAD} = sub { shift->$canonical(@_) };
		return $self->$canonical(@argument);
	}

	my $super = "SUPER::$method";
	return $self->$super(@argument) unless $method =~ /^key[0]*(\d+)$/i;
	my $key = $1;

	my $paramsref = $self->{SvcParams} || [];
	my %svcparams = @$paramsref;

	if ( scalar @argument ) {
		my $arg = shift @argument;			# keyNN($value);
		delete $svcparams{$key} unless defined $arg;
		die( $self->type . qq[: duplicate SvcParam "key$key"] ) if defined $svcparams{$key};
		die( $self->type . qq[: invalid SvcParam "key$key"] )	if $key > 65534;
		die( $self->type . qq[: unexpected "key$key" value] )	if scalar @argument;
		delete $self->{rdata};
		$svcparams{$key} = Net::DNS::Text->new("$arg")->raw if defined $arg;
		$self->{SvcParams} = [map { ( $_, $svcparams{$_} ) } sort { $a <=> $b } keys %svcparams];
	} else {
		die( $self->type . qq[: no value specified for "key$key"] ) unless defined wantarray;
	}

	return $svcparams{$key};
}

########################################


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('name SVCB  SvcPriority TargetName SvcParams');

=head1 DESCRIPTION

DNS Service Binding (SVCB) resource record

Service binding and parameter specification
via the DNS (SVCB and HTTPS RRs)

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 SvcPriority

	$svcpriority = $rr->svcpriority;
	$rr->svcpriority( $svcpriority );

The priority of this record
(relative to others, with lower values preferred). 
A value of 0 indicates AliasMode.

=head2 TargetName

	$rr->targetname( $targetname );
	$effecivetarget = $rr->targetname;

The domain name of either the alias target (for AliasMode)
or the alternative endpoint (for ServiceMode).

For AliasMode SVCB RRs, a TargetName of "." indicates that the
service is not available or does not exist.

For ServiceMode SVCB RRs, a TargetName of "." indicates that the
owner name of this record must be used as the effective TargetName.

=head2 mandatory, alpn, no-default-alpn, port, ipv4hint, ech, ipv6hint

	$rr = Net::DNS::RR->new( 'svcb.example. SVCB 1 svcb.example. port=1234' );

	$rr->port(1234);
	$octets = $rr->port();	# 0x04 0xD2
	$octets = $rr->key3();

Constructor methods for mnemonic SvcParams prescribed by RFC9460.
When invoked without arguments, the methods return the value
of the underlying key as an uninterpreted octet string.
The behaviour with undefined arguments is not specified.

=head2 keyNN

	$keynn = $rr->keyNN;
	$rr->keyNN( $keynn );
	$rr->keyNN( undef );

Generic constructor and accessor methods for SvcParams.
The key index NN is a decimal integer in the range 0 .. 65535.
The method argument is a presentation format character string.
The returned value is an uninterpreted octet string.
The method returns the undefined value if the key is not present.
The specified key will be deleted if the argument is undefined.


=head1 COPYRIGHT

Copyright (c)2020-2025 Dick Franks. 

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
L<RFC9460(2)|https://iana.org/go/rfc9460#section-2>

L<Service Parameter Keys|https://iana.org/assignments/dns-svcb>

=cut
