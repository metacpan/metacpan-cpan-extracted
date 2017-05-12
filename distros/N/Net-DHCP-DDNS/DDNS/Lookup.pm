package Net::DHCP::DDNS::Lookup;
use warnings;
use strict;

use base 'Net::DNS::Resolver';

use Carp;
use Net::IP;

# TODO: implement automatic authority chasing
# 		* is the reply authoritative
# 		* ask for SOA data inline?
# 	locating master name servers

# reply object cache structure
#
# $self->{DNSREPLY}->{$domain}->{$class} = {
# 	packet  => Net::DNS::Packet,
# 	expires => last_valid_epoch,
# 	records => [ Net::DNS::RR, ... ]
# };
# 

my %DNSREPLY;

sub _populate {
	my ( $self, $domain, $class ) = @_;

	$self = __PACKAGE__->new unless ref( $self );

	my $packet = $self->SUPER::send( $domain, 'ANY', $class )
		or croak "DNS problem: ", $self->errorstring, "\n";

	unless ( $packet->header->ancount ) {
		$self->evict( $domain, $class );
		return $packet;
	}

	my $expires = 4000000000; # FIXME real upper limit?

	my $now = time;

	grep {	my $e = $now + $_->ttl;
		$expires = $e if $e < $expires;
	} $packet->answer;

	$DNSREPLY{$domain}->{$class} = {
		packet  => $packet,
		expires => $expires
	};

	return 1;
}

sub _fetch {
	my ( $self, $domain, $class ) = @_;

	return undef unless my $tmp1 = \%DNSREPLY;
	return undef unless my $tmp2 = $tmp1->{$domain};
	return undef unless my $tmp3 = $tmp2->{$class};

	return $tmp3;
}

sub _is_valid {
	my ( $self, $domain, $class ) = @_;

	return 0 unless my $tmp = _fetch( $self, $domain, $class );
	return 0 unless my $exp  = $tmp->{expires};

	return ( $exp < time ) ? 0 : 1;
}

sub _normalize_send_args(@) {
	my ( $arg, $rrtype, $class ) = @_;

	return if ref( $arg );

	my $ip     = new Net::IP $arg;
	my $domain = $ip ? $ip->reverse_ip : $arg;

	$rrtype ||= 'PTR';
	$class  ||= 'IN';

	return ( $domain, $rrtype, $class );
}


# three call modes:
# 	( packetobject )
# 	( domain [ type [ class ] ] )
# 	( address )
#
# packetobject calls are not cached, all others are
#
sub send {
	my $self = shift;

	$self = __PACKAGE__->new unless ref( $self );

	my ( $domain, $rrtype, $class ) = _normalize_send_args( @_ )
		or return $self->SUPER::send( shift );;

	_populate( $self, $domain, $class )
		unless _is_valid( $self, $domain, $class );

	return $self->cached_packet( $domain, $rrtype, $class );
}

#
# arguments same as send()
# returns a copy of the packet object
# if rrtype != ANY, filters the answers
#
sub cached_packet {
	my $self = shift;

	my ( $domain, $rrtype, $class ) = _normalize_send_args( @_ )
		or return undef;

	return undef unless my $tmp = _fetch( $self, $domain, $class );

	my $d = $tmp->{packet}->data;
	my $r = new Net::DNS::Packet \$d;

	my $i = 0;
	foreach my $rr ( @{$r->{answer}} ) {

		if ( $rr->type eq $rrtype ) {
			$i++;
		}

		else {
			splice @{$r->{answer}}, $i, 1;
		}

	}

	unless ( $rrtype eq 'ANY' ) {
		foreach my $q ( @{$r->{question}} ) {
			$q->{qtype} = $rrtype;
		}
	}

	return $r;
}

# arguments same as send()
# returns a list of Net::DNS::RR
# if rrtype != ANY, filters the answers
sub cached_answer {
	my $self = shift;

	my ( $domain, $rrtype, $class ) = _normalize_send_args( @_ )
		or return undef;

	return undef unless my $tmp = _fetch( $self, $domain, $class );

	return @{$tmp->{packet}->{answer}} if $rrtype eq 'ANY';

	return grep { $_->type eq $rrtype } @{$tmp->{packet}->{answer}};
}

# mark the domain cache record as expired
sub invalidate {
	my ( $self, $domain, $class ) = @_;

	return unless $domain;
	$class ||= 'IN';

	return unless my $tmp = _fetch( $self, $domain, $class );
	return unless $tmp->{expires};

	$tmp->{expires} = 0;

	return;
}

# delete the domain cache record entirely
sub evict {
	my ( $self, $domain, $class ) = @_;

	return unless $domain;
	$class ||= 'IN';

	return unless my $tmp1 = \%DNSREPLY;
	return unless my $tmp2 = $tmp1->{$domain};
	return unless my $tmp3 = $tmp2->{$class};

	delete $tmp2->{$class};
	delete $tmp1->{$domain}  unless scalar( %$tmp2 );
#	delete $self->{DNSREPLY} unless scalar( %$tmp1 );

	return;
}


# locate the SOA
sub find_soa {
	my ( $self, $dname ) = @_;

	$self = __PACKAGE__->new unless ref( $self );

	$dname .= '.' unless $dname =~ /\.$/;

	while ( $dname ) {
#warn "domain: $dname\n";
		my $rep = $self->send( $dname, 'SOA' );

		unless ( $rep and $rep->header->ancount ) {
			continue unless $dname =~ /\./;
			$dname =~ s/[^\.]+\.//;
			next;
		}

		foreach my $rr ( ($rep->answer), ($rep->authority) ) {
			next unless $rr->type eq 'SOA';
			return $rr;
		}

		continue unless $dname =~ /\./;
		$dname =~ s/[^\.]+\.//;

	}

	croak "DNS error finding SOA for $dname: ", $self->errorstring;

}

# rfc1464 key=value pairs in dns
sub getattrbyname {
	my ( $self, $dname, $attrname ) = @_;
	my @rv;

	$self = __PACKAGE__->new unless ref( $self );

	$dname .= '.' unless $dname =~ /\.$/;

	$attrname = lc( $attrname );

	my $rep = $self->send( $dname, 'TXT' )
		or return undef;

	foreach my $rr ( $rep->answer ) {
		next unless $rr->type eq 'TXT';
		my $t = $rr->txtdata;

		my ( $key, $value ) = $self->parse_attribute( $t );

		if ( $key eq $attrname ) {
			push @rv, $value;
		}

	}

	return @rv;
}

sub parseattribute {
	my ( $self, $t ) = @_;
	my ( $key, $value, $have_key );

	$t =~ s/\\\\/\\/g;
	$t =~ s/\\"/"/g;

	next unless $t =~ /[^`]=/;
	next if $t =~ /^=/;

	foreach my $p ( split /=/, $t ) {

		if ( $have_key ) {
			$value .= '=' if $value;
			$value .= $p;
			next;
		}

		if ( $p =~ /`$/ ) {
			$p =~ s/`$//;
			$key .= '=' if $key;
			$key .= $p;
			next;
		}

		$key .= '=' if $key;
		$key .= $p;

		$have_key = 1;

	}

	$key = lc( $key );
	$key =~ s/^\s+//;
	$key =~ s/\s+$//;
	$key =~ s/``/`/g;
	$key =~ s/`=/=/g;
	$key =~ s/` / /g;
	$key =~ s/`	/	/g;
	$key = lc( $key );

	return ( $key, $value );
}


1;
