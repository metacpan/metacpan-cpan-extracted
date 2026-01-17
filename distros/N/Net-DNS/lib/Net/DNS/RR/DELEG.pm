package Net::DNS::RR::DELEG;

use strict;
use warnings;
our $VERSION = (qw$Id: DELEG.pm 2043 2026-01-14 13:35:59Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::DELEG - DNS DELEG resource record

=cut

use integer;

use Net::DNS::RR::A;
use Net::DNS::RR::AAAA;
use Net::DNS::DomainName;
use Net::DNS::Text;

my %keybycode = (
	0 => 'mandatory',
	1 => 'server-ipv4',
	2 => 'server-ipv6',
	3 => 'server-name',
	4 => 'include-delegi',
	);
my %keybyname = reverse %keybycode;


sub _decode_rdata {			## decode rdata from wire-format octet string
	my ( $self, $data, $offset ) = @_;

	my $limit = $self->{rdlength};
	my $rdata = $self->{rdata} = substr $$data, $offset, $limit;
	my $index = 0;

	my $params = $self->{parameters} = [];
	while ( ( my $start = $index + 4 ) <= $limit ) {
		my ( $key, $size ) = unpack( "\@$index n2", $rdata );
		last if ( $index = $start + $size ) > $limit;
		push @$params, ( $key, substr $rdata, $start, $size );
	}
	die $self->type . ': corrupt RDATA' unless $index == $limit;
	return;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my $self = shift;

	my @packed;
	my ($paramref) = grep {defined} $self->{parameters}, [];
	my @parameters = @$paramref;
	while (@parameters) {
		my $key = shift @parameters;
		my $val = shift @parameters;
		push @packed, pack( 'n2a*', $key, length($val), $val );
	}
	return join '', @packed;
}


sub _format_rdata {			## format rdata portion of RR string.
	my $self = shift;

	my @rdata;
	my ($paramref) = grep {defined} $self->{parameters}, [];
	my @parameters = @$paramref;
	while (@parameters) {
		my $key = shift @parameters;
		my $val = shift @parameters;
		if ( my $name = $keybycode{$key} ) {
			my @val = grep {length} $self->$name;
			my @rhs = grep {length} join ',', @val;
			push @rdata, join '=', $name, @rhs;
		} else {
			my $txt = Net::DNS::Text->decode( \$val, 0, length $val );
			push @rdata, join '=', "key$key", $txt->string;
		}
	}

	return @rdata;
}


sub _parse_rdata {			## populate RR from rdata in argument list
	my ( $self, @argument ) = @_;

	while ( local $_ = shift @argument ) {
		m/^([^=]+)(=?)(.*)$/;
		my $key = $1;
		my $val = length($3) ? $3 : $2 ? shift @argument : '';
		if (/^key\d+/) {
			$self->$key($val);
		} else {
			local $_ = $val;
			s/^"([^"]*)"$/$1/s;			# strip enclosing quotes
			s/\\,/\\044/g;				# disguise escaped comma
			$self->$key( split /,/ );
		}
	}
	return;
}


sub _post_parse {			## parser post processing
	my $self = shift;

	my ($paramref) = grep {defined} $self->{parameters}, [];
	my %parameter  = @$paramref;

	if ( defined $parameter{0} ) {
		my %unique;
		foreach ( grep { !$unique{$_}++ } unpack 'n*', $parameter{0} ) {
			die( $self->type . qq[: unexpected "key0" in mandatory list] ) if $unique{0};
			die( $self->type . qq[: duplicate "key$_" in mandatory list] ) if --$unique{$_};
			die( $self->type . qq[: mandatory "key$_" not present] ) unless defined $parameter{$_};
		}
	}

	foreach ( 3, 4 ) {
		next unless defined $parameter{$_};
		next if length( $parameter{$_} ) > 1;
		die( $self->type . qq[: invalid $keybycode{$_}] );
	}

	if ( defined $parameter{4} ) {
		die( $self->type . qq[: parameter conflicts with $keybycode{4}] )
				if scalar( keys %parameter ) > 1;
	}
	return;
}


sub mandatory {				## mandatory=key1,server-name,...
	my ( $self, @value ) = @_;				# uncoverable pod
	my @list = map { $keybyname{lc $_} || $_ } @value;
	my @keys = map { /(\d+)$/ ? $1 : die( $self->type . qq[: unexpected "$_"] ) } @list;
	return $self->_parameter( 0, _integer16( sort { $a <=> $b } @keys ) ) if @keys;
	my $packed = $self->_parameter(0);
	return _list( defined($packed) ? map {"key$_"} unpack 'n*', $packed : return );
}

sub server_ipv4 {			## server-ipv4=192.0.2.53
	my ( $self, @value ) = @_;
	return $self->_parameter( 1, _address4(@value) ) if @value;
	my $packed = $self->_parameter(1) || return;
	my @iplist = unpack 'a4' x ( length($packed) / 4 ), $packed;
	return _list( map { Net::DNS::RR::A::address( {address => $_} ) } @iplist );
}

sub server_ipv6 {			## server-ipv6=2001:DB8::53
	my ( $self, @value ) = @_;
	return $self->_parameter( 2, _address6(@value) ) if @value;
	my $packed = $self->_parameter(2) || return;
	my @iplist = unpack 'a16' x ( length($packed) / 16 ), $packed;
	return _list( map { Net::DNS::RR::AAAA::address_short( {address => $_} ) } @iplist );
}

sub server_name {			## server-name=nameserver.example
	my ( $self, @value ) = @_;
	return $self->_parameter( 3, _domain(@value) ) if @value;
	my $packed = $self->_parameter(3) || return;
	my $index  = 0;
	( $value[++$#value], $index ) = Net::DNS::DomainName->decode( \$packed, $index ) while $index < length $packed;
	return _list( map { $_->fqdn } @value );
}

sub include_delegi {			## include-delegi=devolved.example
	my ( $self, @value ) = @_;
	return $self->_parameter( 4, _domain(@value) ) if @value;
	my $packed = $self->_parameter(4) || return;
	my $index  = 0;
	( $value[++$#value], $index ) = Net::DNS::DomainName->decode( \$packed, $index ) while $index < length $packed;
	return _list( map { $_->fqdn } @value );
}


########################################

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
	return $self->_parameter($key) unless @argument;
	my $first = shift @argument;
	my $value = defined $first ? Net::DNS::Text->new($first)->raw : $first;
	return $self->_parameter( $key, $value, @argument );
}


sub _parameter {
	my ( $self, $key, @argument ) = @_;

	my ($paramref) = grep {defined} $self->{parameters}, [];
	my %parameter  = @$paramref;

	if ( scalar @argument ) {
		my $arg = shift @argument;			# key($value);
		delete $parameter{$key} unless defined $arg;
		die( $self->type . qq[: duplicate parameter key$key] ) if defined $parameter{$key};
		die( $self->type . qq[: unexpected key$key value] )    if scalar @argument;
		delete $self->{rdata};
		$parameter{$key} = $arg if defined $arg;
		$self->{parameters} = [map { ( $_, $parameter{$_} ) } sort { $a <=> $b } keys %parameter];
	}

	return $parameter{$key};
}


sub _concatenate {			## concatenate octet string(s)
	my @arg = @_;
	return scalar(@arg) > 1 ? join( '', @arg ) : @arg;
}

sub _list {				## context-dependent list or single value
	my @arg = @_;
	return wantarray ? @arg : shift @arg;
}

sub _address4 {
	my @arg = @_;
	return _concatenate( map { Net::DNS::RR::A::address( {}, $_ ) } @arg );
}

sub _address6 {
	my @arg = @_;
	return _concatenate( map { Net::DNS::RR::AAAA::address( {}, $_ ) } @arg );
}

sub _domain {
	my @arg = @_;
	return _concatenate( map { Net::DNS::DomainName->new($_)->encode() } @arg );
}

sub _integer16 {
	my @arg = @_;
	return _concatenate( map { pack( 'n', $_ ) } @arg );
}


sub generic {
	my $self = shift;
	my $size = 0;
	my @rdata;
	my ($paramref) = grep {defined} $self->{parameters}, [];
	my @parameters = @$paramref;
	while (@parameters) {
		my $key = shift @parameters;
		my $val = shift @parameters;
		push @rdata, "\n", unpack 'H4H4', pack( 'n2', $key, length $val );
		$size += 4 + length $val;
		push @rdata, split /(\S{32})/, unpack 'H*', $val;
	}

	my @ttl	  = grep {defined} $self->{ttl};
	my @class = map	 { $_ ? "CLASS$_" : () } $self->{class};
	my @core  = ( $self->{owner}->string, @ttl, @class, "TYPE$self->{type}" );
	return join "\n\t", Net::DNS::RR::_wrap( "@core ( \\# $size", @rdata, ')' );
}

########################################


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('zone DELEG server-ipv4=192.0.2.1 ...');
	$rr = Net::DNS::RR->new('zone DELEG server-ipv6=2001:db8::53 ...');
	$rr = Net::DNS::RR->new('zone DELEG server-name=nameserver.example ...');
	$rr = Net::DNS::RR->new('zone DELEG include-delegi=devolved.example');

=head1 DESCRIPTION

The DNS DELEG resource record set, wherever it appears, designates the
authoritative nameservers and transport parameters to be used to resolve
queries for data at the owner name or any subordinate thereof.

The DELEG RRset is authoritative data within the delegating zone.
A DELEG RRset must not appear at the apex of a delegated zone.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 server_ipv4

	eg.example. DELEG server-ipv4=192.0.2.1,...
	@ip = $rr->server_ipv4;

Sets or gets a list of IP addresses.


=head2 server_ipv6

	eg.example. DELEG server-ipv6=2001:db8::53,...
	@ip = $rr->server_ipv6;

Sets or gets a list of IP addresses.


=head2 server_name

	eg.example. DELEG server-name=nameserver.example.
	$nameserver = $rr->server_name;

Specifies the domain name of the nameserver.

Returns the nameserver domain name or the undefined value if not specified.


=head2 include_delegi

	eg.example. DELEG include-delegi=devolved.example.
	$destination = $rr->include_delegi;

Specifies the location of a devolved nameserver configuration.

Returns the destination domain name or the undefined value if not specified.


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
draft-ietf-deleg-06

=cut
