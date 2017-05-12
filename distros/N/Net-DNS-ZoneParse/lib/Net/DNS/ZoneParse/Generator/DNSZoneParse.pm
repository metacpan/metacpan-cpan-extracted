package Net::DNS::ZoneParse::Generator::DNSZoneParse;

use 5.008000;
use strict;
use warnings;
use vars qw($VERSION);

use Net::DNS;
use DNS::ZoneParse;
use Net::DNS::ZoneParse::Parser::DNSZoneParse;

my %soamap = %Net::DNS::ZoneParse::Parser::DNSZoneParse::soamap;
my %rrmap = %Net::DNS::ZoneParse::Parser::DNSZoneParse::rrmap;

$VERSION = 0.103;

=pod

=head1 NAME

Net::DNS::ZoneParse::Generator::DNSZoneParse - generator glue for
Net::DNS::ZoneParse to use DNS::ZoneParse.

=head1 DESCRIPTION

=cut

my %type = (
	SOA => sub {
		my ($rr, $zone) = @_;
		my $soa = $zone->soa();
		map { $soa->{$soamap{$_}} = $rr->{$_} } keys %soamap;
	},
);

sub _unmap {
	my ($rr, $zone) = @_;
	my $type = lc($rr->{type});
	return unless $rrmap{$type};
	my $list = eval("\$zone->$type()");
	push(@{$list}, { map { $rrmap{$type}->{$_} => $rr->{$_} }
		       	keys %{$rrmap{$type}} });
}

=pod

=head2 EXPORT

=head3 generate

This will be called by the Interface of Net::DNS:ZoneParse and return the
corresponding zonetext.

=cut

sub generate {
	my ($self, $param) = @_;

	my $text = "";
	my $zone = $param->{parser_arg}->{zone};
	if($zone) {
		for(keys %rrmap) {
			my $ref = eval("\$zone->$_");
			pop(@{$ref}) while($#{$ref} >= 0);
		}
	} else {
		$zone = DNS::ZoneParse->new(\$text, $param->{origin});
	}
	map { $type{$_->{type}}?$type{$_->{type}}($_, $zone):_unmap($_, $zone) } @{$param->{rr}};
	return $zone->output();
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
