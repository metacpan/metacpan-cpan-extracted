package Net::DNS::RR::TKEY;

use strict;
use warnings;
our $VERSION = (qw$Id: TKEY.pm 2003 2025-01-21 12:06:06Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::TKEY - DNS TKEY resource record

=cut

use integer;

use Carp;

use Net::DNS::Parameters qw(:class :type);
use Net::DNS::DomainName;

use constant ANY  => classbyname qw(ANY);
use constant TKEY => typebyname	 qw(TKEY);


sub _decode_rdata {			## decode rdata from wire-format octet string
	my ( $self, $data, $offset ) = @_;

	my $limit = $offset + $self->{rdlength};

	( $self->{algorithm}, $offset ) = Net::DNS::DomainName->decode( $data, $offset );

	@{$self}{qw(inception expiration mode error)} = unpack "\@$offset N2n2", $$data;
	$offset += 12;

	my $key_size = unpack "\@$offset n", $$data;
	$self->{key} = substr $$data, $offset + 2, $key_size;
	$offset += $key_size + 2;

	my $other_size = unpack "\@$offset n", $$data;
	$self->{other} = substr $$data, $offset + 2, $other_size;
	$offset += $other_size + 2;

	croak('corrupt TKEY data') unless $offset == $limit;	# more or less FUBAR
	return;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my $self = shift;

	return '' unless defined $self->{algorithm};
	my $rdata = $self->{algorithm}->encode;

	$rdata .= pack 'N2n2', $self->inception, $self->expiration, $self->mode, $self->error;

	my $key = $self->key;					# RFC2930(2.7)
	$rdata .= pack 'na*', length $key, $key;

	my $other = $self->other;				# RFC2930(2.8)
	$rdata .= pack 'na*', length $other, $other;
	return $rdata;
}


sub class {				## override RR method
	return 'ANY';
}

sub encode {				## override RR method
	my $self = shift;

	my $owner = $self->{owner}->encode();
	my $rdata = eval { $self->_encode_rdata() } || '';
	return pack 'a* n2 N n a*', $owner, TKEY, ANY, 0, length $rdata, $rdata;
}


sub algorithm {
	my ( $self, @value ) = @_;
	for (@value) { $self->{algorithm} = Net::DNS::DomainName->new($_) }
	return $self->{algorithm} ? $self->{algorithm}->name : undef;
}


sub inception {
	my ( $self, @value ) = @_;
	for (@value) { $self->{inception} = 0 + $_ }
	return $self->{inception} || 0;
}


sub expiration {
	my ( $self, @value ) = @_;
	for (@value) { $self->{expiration} = 0 + $_ }
	return $self->{expiration} || 0;
}


sub mode {
	my ( $self, @value ) = @_;
	for (@value) { $self->{mode} = 0 + $_ }
	return $self->{mode} || 0;
}


sub error {
	my ( $self, @value ) = @_;
	for (@value) { $self->{error} = 0 + $_ }
	return $self->{error} || 0;
}


sub key {
	my ( $self, @value ) = @_;
	for (@value) { $self->{key} = $_ }
	return $self->{key} || "";
}


sub other {
	my ( $self, @value ) = @_;
	for (@value) { $self->{other} = $_ }
	return $self->{other} || "";
}


sub other_data { return &other; }				# uncoverable pod


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = new Net::DNS::RR('example.com IN TKEY ...	');

=head1 DESCRIPTION

Class for DNS TSIG Key (TKEY) resource records.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 algorithm

	$algorithm = $rr->algorithm;
	$rr->algorithm( $algorithm );

The algorithm name is in the form of a domain name with the same
meaning as in [RFC 2845].  The algorithm determines how the secret
keying material agreed to using the TKEY RR is actually used to derive
the algorithm specific key.

=head2 inception

	$inception = $rr->inception;
	$rr->inception( $inception );

Time expressed as the number of non-leap seconds modulo 2**32 since the
beginning of January 1970 GMT.

=head2 expiration

	$expiration = $rr->expiration;
	$rr->expiration( $expiration );

Time expressed as the number of non-leap seconds modulo 2**32 since the
beginning of January 1970 GMT.

=head2 mode

	$mode = $rr->mode;
	$rr->mode( $mode );

The mode field specifies the general scheme for key agreement or the
purpose of the TKEY DNS message, as defined in [RFC2930(2.5)].

=head2 error

	$error = $rr->error;
	$rr->error( $error );

The error code field is an extended RCODE.

=head2 key

	$key = $rr->key;
	$rr->key( $key );

Sequence of octets representing the key exchange data.
The meaning of this data depends on the mode.

=head2 other

	$other = $rr->other;
	$rr->other( $other );

Content not defined in the [RFC2930] specification but may be used
in future extensions.


=head1 COPYRIGHT

Copyright (c)2000 Andrew Tridgell. 

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
L<RFC2930|https://iana.org/go/rfc2930>

=cut
