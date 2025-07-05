package Net::DNS::RR::DELEG;

use strict;
use warnings;
our $VERSION = (qw$Id: DELEG.pm 2021 2025-07-04 13:00:27Z willem $)[2];

use base qw(Net::DNS::RR::SVCB);


=head1 NAME

Net::DNS::RR::DELEG - DNS DELEG resource record

=cut

use integer;

use Carp;

my %keyname = reverse(
	IPv4addr => 'key4',
	IPv6addr => 'key6',
	);


sub _format_rdata {			## format rdata portion of RR string.
	my $self = shift;

	my $priority = $self->{SvcPriority};
	my $mode     = $priority ? 'DIRECT' : 'INCLUDE';
	my @rdata    = join '=', $mode, $self->{TargetName}->string;
	push @rdata, "\n", join '=', 'Priority', $priority if $priority > 1;

	my $params = $self->{SvcParams} || [];
	my @params = @$params;
	while (@params) {
		my $key = join '', 'key', shift @params;
		my $val = shift @params;
		if ( my $name = $keyname{$key} ) {
			my @val = $self->$name;
			push @rdata, "\n", length($val) ? "$name=@val" : "$name";
		} else {
			my @hex = unpack 'H*', $val;
			$self->_annotation(qq(unexpected $key="@hex"));
		}
	}

	return @rdata;
}


sub _parse_rdata {			## populate RR from rdata in argument list
	my ( $self, @argument ) = @_;

	local $SIG{__WARN__} = sub { die @_ };
	while ( my $parameter = shift @argument ) {
		for ($parameter) {
			my @value;
			if (/^key\d+.*$/i) {			# reject SVCB generic key
				my $rhs = /=$/ ? shift @argument : '';
				croak "Unexpected parameter: $_$rhs";
			} elsif (/^[^=]+=(.*)$/) {
				local $_ = length($1) ? $1 : shift @argument;
				s/^"([^"]*)"$/$1/;		# strip enclosing quotes
				s/\\,/\\044/g;			# disguise escaped comma
				push @value, split /,/;
			}

			s/[-]/_/g;				# extract identifier
			m/^([^=]+)/;
			$self->$1(@value);
		}
	}
	return;
}


sub DIRECT {
	my ( $self, $servername ) = @_;				# uncoverable pod
	$self->{SvcPriority} = 1;
	$self->{TargetName}  = Net::DNS::DomainName->new($servername);
	return;
}

sub INCLUDE {
	my ( $self, $target ) = @_;				# uncoverable pod
	$self->{SvcPriority} = 0;
	$self->{TargetName}  = Net::DNS::DomainName->new($target);
	return;
}

sub priority {
	my ( $self, @value ) = @_;				# uncoverable pod
	my @arg = $self->{SvcPriority} ? @value : ();
	return $self->SvcPriority(@arg) || croak 'Priority invalid for INCLUDE';
}

sub glue4 {				## glue4=192.0.2.53,...
	my ( $self, @value ) = @_;
	my $ip = $self->ipv4hint(@value);
	return $ip if @value;
	my @ip = unpack 'a4' x ( length($ip) / 4 ), $ip;
	return join ',', map { bless( {address => $_}, 'Net::DNS::RR::A' )->address } @ip;
}

sub glue6 {				## glue6=2001:DB8::53,...
	my ( $self, @value ) = @_;
	my $ip = $self->ipv6hint(@value);
	return $ip if @value;
	my @ip = unpack 'a16' x ( length($ip) / 16 ), $ip;
	return join ',', map { bless( {address => $_}, 'Net::DNS::RR::AAAA' )->address } @ip;
}

sub ipv4addr { return &glue4 }
sub ipv6addr { return &glue6 }


sub generic {
	my $self  = shift;
	my @ttl	  = grep {defined} $self->{ttl};
	my @class = map	 {"CLASS$_"} grep {defined} $self->{class};
	my @core  = ( $self->{owner}->string, @ttl, @class, "TYPE$self->{type}" );
	my @rdata = $self->_empty ? () : $self->SUPER::_format_rdata;
	return join "\n\t", Net::DNS::RR::_wrap( "@core (", @rdata, ')' );
}


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('zone DELEG INCLUDE=targetname');
	$rr = Net::DNS::RR->new('zone DELEG DIRECT=nameserver IPv4addr=192.0.2.1 IPv6addr=2001:db8::53');

=head1 DESCRIPTION


The DNS DELEG resource record appears in, and is logically a part of,
the parent zone to mark the delegation point for a child zone.
It advertises, directly or indirectly, transport methods
available for connection to nameservers serving the child zone.

The DELEG class is derived from, and inherits properties of,
the Net::DNS::RR::SVCB class.


=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.



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

L<RFC9460|https://iana.org/go/rfc9460>

L<Service Parameter Keys|https://iana.org/assignments/dns-svcb>

=cut
