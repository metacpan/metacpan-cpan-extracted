package Net::DNS::ZoneParse::Parser::DNSZoneParse;

use 5.008000;
use strict;
use warnings;
use vars qw($VERSION);

use Net::DNS;
use DNS::ZoneParse;

$VERSION = 0.103;

=pod

=head1 NAME

Net::DNS::ZoneParse::Parser::DNSZoneParse - Glue for Net::DNS::ZoneParse to
use DNS::ZoneParse.

=head1 DESCRIPTION

DNSZoneParse uses DNS::ZoneParse as parsing engine.

=head2 EXPORT

=head3 parse

	$rr = Net::DNS::ZoneParse::Parser::DNSZoneParse->parse($param)

This will be called by Net::DNS::ZoneParse

=cut

our %soamap = (
	mname => "primary",
	rname => "email",
	serial => "serial",
	refresh => "refresh",
	retry => "retry",
	expire => "expire",
	minimum => "minimumTTL",
	ttl => "ttl",
	class => "class",
	name => "origin",
);

our %rrmap = (
	a => {
		name => "name",
		ttl => "ttl",
		class => "class",
		address => "host",
	},
	cname => {
		name => "name",
		ttl => "ttl",
		class => "class",
		cname => "host",
	},
	mx => {
		name => "name",
		ttl => "ttl",
		class => "class",
		preference => "priority",
		exchange => "host",
	},
	srv => {
		name => "name",
		ttl => "ttl",
		class => "class",
		priority => "priority",
		weight => "weight",
		port => "port",
		target => "host",
	},
	ns => {
		name => "name",
		ttl => "ttl",
		class => "class",
		nsdname => "host",
	},
	ptr => {
		name => "name",
		ttl => "ttl",
		class => "class",
		ptrdname => "host",
	},
	txt => {
		name => "name",
		ttl => "ttl",
		class => "class",
		txtdata => "text",
	},
	hinfo => {
		name => "name",
		ttl => "ttl",
		class => "class",
		cpu => "cpu",
		os => "os",
	},
	rp => {
		name => "name",
		ttl => "ttl",
		class => "class",
		mbox => "mbox",
		txtdname => "text",
	},
	loc => {
		name => "name",
		ttl => "ttl",
		class => "class",
		size => "siz",
		horiz_pre => "hp",
		vert_pre => "vp",
		latitude => "d1",
		longitude => "m1",
		latlon => "s1",
		altitude => "alt",
	},
);

sub _stripdot {
	$_[0] = substr($_[0], 0, -1) if(substr($_[0], -1) eq ".");
	return $_[0];
}

sub _zpi2rr {
	my ($type, $item) = @_;
	return { type => uc($type), map { $_ => _stripdot($item->{$rrmap{$type}->{$_}}) } keys %{$rrmap{$type}}};
}

sub _zp2rr {
	my ($type, $zone) = @_;

	my $utype = uc($type);
	my $arr = eval("\$zone->$type");
	return map { _zpi2rr($type, $_) } @{$arr};
}

sub parse {
	my ($self, $param) = @_;
	my $fh = $param->{fh};
	my $zonetext = <<"ZONESTART";
\$ORIGIN $param->{origin}
\$TTL $param->{ttl}
ZONESTART
	$zonetext .= join "",<$fh>;
	my $zone = DNS::ZoneParse->new(\$zonetext, $param->{origin});
	$param->{parser_arg}->{zone} = $zone;
	my @rr;
	my $soa = $zone->soa();
	if(keys %{$soa}) {
		push(@rr, Net::DNS::RR->new_from_hash(type => "SOA",
			       	map { $_ => $soa->{$soamap{$_}}} keys %soamap));
	}
	push(@rr, map { _zp2rr($_, $zone) } keys %rrmap);
	return \@rr;
}


=pod

=head1 SEE ALSO

Net::DNS::ZoneParse
DNS::ZoneParse

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
