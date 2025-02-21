package Net::DNS::RR::DSYNC;

use strict;
use warnings;
our $VERSION = (qw$Id: DSYNC.pm 2003 2025-01-21 12:06:06Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::DSYNC - DNS DSYNC resource record

=cut

use integer;

use Net::DNS::Parameters qw(:type);
use Net::DNS::DomainName;


sub _decode_rdata {			## decode rdata from wire-format octet string
	my ( $self, $data, $offset, @opaque ) = @_;

	@{$self}{qw(rrtype scheme port)} = unpack "\@$offset nCn", $$data;
	$self->{target} = Net::DNS::DomainName->decode( $data, $offset + 5, @opaque );
	return;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my $self = shift;

	my $target = $self->{target};
	return pack 'nCn a*', @{$self}{qw(rrtype scheme port)}, $target->encode;
}


sub _format_rdata {			## format rdata portion of RR string.
	my $self = shift;

	my @params = map { $self->$_ } qw(rrtype scheme port);
	my $target = $self->{target};
	return ( @params, $target->string );
}


sub _parse_rdata {			## populate RR from rdata in argument list
	my ( $self, @argument ) = @_;

	$self->$_( shift @argument ) foreach qw(rrtype scheme port target);
	return;
}


sub rrtype {
	my ( $self, @value ) = @_;
	for (@value) { $self->{rrtype} = typebyname($_) }
	my $typecode = $self->{rrtype};
	return defined $typecode ? typebyval($typecode) : undef;
}


sub scheme {
	my ( $self, @value ) = @_;
	for (@value) { $self->{scheme} = 0 + $_ }
	return $self->{scheme} || 0;
}


sub port {
	my ( $self, @value ) = @_;
	for (@value) { $self->{port} = 0 + $_ }
	return $self->{port} || 0;
}


sub target {
	my ( $self, @value ) = @_;
	for (@value) { $self->{target} = Net::DNS::DomainName->new($_) }
	return $self->{target} ? $self->{target}->name : undef;
}


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('name DSYNC rrtype scheme port target');

=head1 DESCRIPTION

Class for DNS Generalized Notify (DSYNC) resource records.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 rrtype

	$rrtype = $rr->rrtype;
	$rr->rrtype($rrtype);

The type of generalized NOTIFY for which this DSYNC RR defines the
desired target address.

=head2 scheme

	$scheme = $rr->scheme;
	$rr->scheme( $scheme );

The scheme indicates the mode used for locating the notification address.
This is an 8 bit unsigned integer.
Records with value 0 (null scheme) are ignored by consumers.

=head2 port

	$port = $rr->port;
	$rr->port( $port );

The port on the host providing the notification service.
This is a 16 bit unsigned integer.

=head2 target

	$target = $rr->target;
	$rr->target( $target );

The domain name of the target host providing the service
which listens for notifications of the specified type.
This name MUST resolve to one or more address records.


=head1 COPYRIGHT

Copyright (c)2024 Dick Franks. 

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
draft-ietf-dnsop-generalized-notify

=cut
