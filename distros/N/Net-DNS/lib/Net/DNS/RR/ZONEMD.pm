package Net::DNS::RR::ZONEMD;

#
# $Id: ZONEMD.pm 1761 2020-01-01 11:58:34Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1761 $)[1];


use strict;
use warnings;
use base qw(Net::DNS::RR);

=head1 NAME

Net::DNS::RR::ZONEMD - DNS ZONEMD resource record

=cut


use integer;

use Carp;


sub _decode_rdata {			## decode rdata from wire-format octet string
	my $self = shift;
	my ( $data, $offset ) = @_;

	my $rdata = substr $$data, $offset, $self->{rdlength};
	@{$self}{qw(serial digtype parameter digestbin)} = unpack 'NC2a*', $rdata;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my $self = shift;

	pack 'NC2a*', @{$self}{qw(serial digtype parameter digestbin)};
}


sub _format_rdata {			## format rdata portion of RR string.
	my $self = shift;

	my @digest = split /(\S{64})/, $self->digest || qq("");
	my @rdata  = ( @{$self}{qw(serial digtype parameter)}, @digest );
}


sub _parse_rdata {			## populate RR from rdata in argument list
	my $self = shift;

	$self->serial(shift);
	$self->digtype(shift);
	$self->parameter(shift);
	$self->digest(@_);
}


sub _defaults {				## specify RR attribute default values
	my $self = shift;

	$self->_parse_rdata( 0, 1, 0, '' );
}


sub serial {
	my $self = shift;

	$self->{serial} = 0 + shift if scalar @_;
	$self->{serial} || 0;
}


sub digtype {
	my $self = shift;

	$self->{digtype} = 0 + shift if scalar @_;
	$self->{digtype} || 0;
}


sub parameter {
	my $self = shift;

	$self->{parameter} = 0 + shift if scalar @_;
	$self->{parameter} || 0;
}


sub digest {
	my $self = shift;
	return unpack "H*", $self->digestbin() unless scalar @_;
	$self->digestbin( pack "H*", join "", map { /^"*([\dA-Fa-f]*)"*$/ || croak("corrupt hex"); $1 } @_ );
}


sub digestbin {
	my $self = shift;

	$self->{digestbin} = shift if scalar @_;
	$self->{digestbin} || "";
}


1;
__END__


=head1 SYNOPSIS

    use Net::DNS;
    $rr = new Net::DNS::RR("zone. ZONEMD 2018121500 1 0
	FEBE3D4CE2EC2FFA4BA99D46CD69D6D29711E55217057BEE
	7EB1A7B641A47BA7FED2DD5B97AE499FAFA4F22C6BD647DE");

=head1 DESCRIPTION

Class for DNS Zone Message Digest (ZONEMD) resource record.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 serial

    $serial = $rr->serial;
    $rr->serial( $serial );

Unsigned 32-bit integer zone serial number.

=head2 digtype

    $digtype = $rr->digtype;
    $rr->digtype( $digtype );

8-bit integer digest type field.

=head2 parameter

    $parameter = $rr->parameter;
    $rr->parameter( $parameter );

Digest algorithm parameter field.

=head2 digest

    $digest = $rr->digest;
    $rr->digest( $digest );

Hexadecimal representation of the digest over the zone content.

=head2 digestbin

    $digestbin = $rr->digestbin;
    $rr->digestbin( $digestbin );

Binary representation of the digest over the zone content.


=head1 COPYRIGHT

Copyright (c)2019 Dick Franks.

All rights reserved.

Package template (c)2009,2012 O.M.Kolkman and R.W.Franks.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the above copyright notice appear in all copies and that both that
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

L<perl>, L<Net::DNS>, L<Net::DNS::RR>, draft-wessels-dns-zone-digest

=cut
