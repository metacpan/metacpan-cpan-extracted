package Net::DNS::Question;

use strict;
use warnings;

our $VERSION = (qw$Id: Question.pm 2002 2025-01-07 09:57:46Z willem $)[2];


=head1 NAME

Net::DNS::Question - DNS question record

=head1 SYNOPSIS

	use Net::DNS::Question;

	$question = Net::DNS::Question->new('example.com', 'AAAA', 'IN');

=head1 DESCRIPTION

A Net::DNS::Question object represents a record in the question
section of a DNS packet.

=cut


use integer;
use Carp;

use Net::DNS::Parameters qw(%classbyname %typebyname :class :type);
use Net::DNS::Domain;
use Net::DNS::DomainName;


=head1 METHODS

=head2 new

	$question = Net::DNS::Question->new('example.com', 'AAAA', 'IN');
	$question = Net::DNS::Question->new('example.com', 'A', 'IN');
	$question = Net::DNS::Question->new('example.com');

	$question = Net::DNS::Question->new('2001::DB8::dead:beef', 'PTR', 'IN');
	$question = Net::DNS::Question->new('2001::DB8::dead:beef');

Creates a question object from the domain, type, and class passed as
arguments. One or both type and class arguments may be omitted and
will assume the default values shown above.

RFC4291 and RFC4632 IP address/prefix notation is supported for
queries in both in-addr.arpa and ip6.arpa namespaces.

=cut

sub new {
	my $self   = bless {}, shift;
	my $qname  = shift;
	my $qtype  = shift || '';
	my $qclass = shift || '';

	# tolerate (possibly unknown) type and class in zone file order
	unless ( exists $classbyname{$qclass} ) {
		( $qtype, $qclass ) = ( $qclass, $qtype ) if exists $classbyname{$qtype};
		( $qtype, $qclass ) = ( $qclass, $qtype ) if $qtype =~ /CLASS/;
	}
	unless ( exists $typebyname{$qtype} ) {
		( $qtype, $qclass ) = ( $qclass, $qtype ) if exists $typebyname{$qclass};
		( $qtype, $qclass ) = ( $qclass, $qtype ) if $qclass =~ /TYPE/;
	}

	# if argument is an IP address, do appropriate reverse lookup
	if ( defined $qname and $qname =~ m/:|\d$/ ) {
		if ( my $reverse = _dns_addr($qname) ) {
			$qname = $reverse;
			$qtype ||= 'PTR';
		}
	}

	$self->{qname}	= Net::DNS::DomainName1035->new($qname);
	$self->{qtype}	= typebyname( $qtype   || 'A' );
	$self->{qclass} = classbyname( $qclass || 'IN' );

	return $self;
}


=head2 decode

	$question = Net::DNS::Question->decode(\$data, $offset);

	($question, $offset) = Net::DNS::Question->decode(\$data, $offset);

Decodes the question record at the specified location within a DNS
wire-format packet.  The first argument is a reference to the buffer
containing the packet data.  The second argument is the offset of
the start of the question record.

Returns a Net::DNS::Question object and the offset of the next
location in the packet.

An exception is raised if the object cannot be created
(e.g., corrupt or insufficient data).

=cut

use constant QFIXEDSZ => length pack 'n2', (0) x 2;

sub decode {
	my ( $class, @argument ) = @_;
	my ( $data,  $offset )	 = @argument;
	my $self = bless {}, $class;

	( $self->{qname}, $offset ) = Net::DNS::DomainName1035->decode(@argument);

	my $next = $offset + QFIXEDSZ;
	die 'corrupt wire-format data' if length $$data < $next;
	@{$self}{qw(qtype qclass)} = unpack "\@$offset n2", $$data;

	return wantarray ? ( $self, $next ) : $self;
}


=head2 encode

	$data = $question->encode( $offset, $hash );

Returns the Net::DNS::Question in binary format suitable for
inclusion in a DNS packet buffer.

The optional arguments are the offset within the packet data where
the Net::DNS::Question is to be stored and a reference to a hash
table used to index compressed names within the packet.

=cut

sub encode {
	my ( $self, @opaque ) = @_;
	return pack 'a* n2', $self->{qname}->encode(@opaque), @{$self}{qw(qtype qclass)};
}


=head2 string

	print "string = ", $question->string, "\n";

Returns a string representation of the question record.

=cut

sub string {
	my $self = shift;
	return join "\t", $self->{qname}->string, $self->qclass, $self->qtype;
}


=head2 print

	$object->print;

Prints the record to the standard output.  Calls the string() method
to get the string representation.

=cut

sub print {
	print &string, "\n";
	return;
}


=head2 name

	$name = $question->name;

Internationalised domain name corresponding to the qname attribute.

Decoding non-ASCII domain names is computationally expensive and
undesirable for names which are likely to be used to construct
further queries.

When required to communicate with humans, the 'proper' domain name
should be extracted from a query or reply packet.

	$query = Net::DNS::Packet->new( $example, 'SOA' );
	$reply = $resolver->send($query) or die;
	($question) = $reply->question;
	$name = $question->name;

=cut

sub name {
	my ( $self, @argument ) = @_;
	for (@argument) { croak 'immutable object: argument invalid' }
	return $self->{qname}->xname;
}


=head2 qname, zname

	$qname = $question->qname;
	$zname = $question->zname;

Fully qualified domain name in the form required for a query
transmitted to a nameserver.  In dynamic update packets, this
attribute is known as zname() and refers to the zone name.

=cut

sub qname {
	my ( $self, @argument ) = @_;
	for (@argument) { croak 'immutable object: argument invalid' }
	return $self->{qname}->name;
}

sub zname { return &qname; }


=head2 qtype, ztype, type

	$qtype = $question->type;
	$qtype = $question->qtype;
	$ztype = $question->ztype;

Returns the question type attribute.  In dynamic update packets,
this attribute is known as ztype() and refers to the zone type.

=cut

sub type {
	my ( $self, @argument ) = @_;
	for (@argument) { croak 'immutable object: argument invalid' }
	return typebyval( $self->{qtype} );
}

sub qtype { return &type; }
sub ztype { return &type; }


=head2 qclass, zclass, class

	$qclass = $question->class;
	$qclass = $question->qclass;
	$zclass = $question->zclass;

Returns the question class attribute.  In dynamic update packets,
this attribute is known as zclass() and refers to the zone class.

=cut

sub class {
	my ( $self, @argument ) = @_;
	for (@argument) { croak 'immutable object: argument invalid' }
	return classbyval( $self->{qclass} );
}

sub qclass { return &class; }
sub zclass { return &class; }


########################################

sub _dns_addr {				## Map IP address into reverse lookup namespace
	local $_ = shift;

	# IP address must contain address characters only
	s/[%].+$//;						# discard RFC4007 scopeid
	return unless m#^[a-fA-F0-9:./]+$#;

	my ( $address, $pfxlen ) = split m#/#;

	# map IPv4 address to in-addr.arpa space
	if (m#^\d*[.\d]*\d(/\d+)?$#) {
		my @parse = split /\./, $address;
		$pfxlen = scalar(@parse) << 3 unless $pfxlen;
		my $last = $pfxlen > 24 ? 3 : ( $pfxlen - 1 ) >> 3;
		return join '.', reverse( ( @parse, (0) x 3 )[0 .. $last] ), 'in-addr.arpa.';
	}

	# map IPv6 address to ip6.arpa space
	return unless m#^[:\w]+:([.\w]*)(/\d+)?$#;
	my $rhs = $1 || '0';
	return _dns_addr($rhs) if m#^[:0]*:0*:[fF]{4}:[^:]+$#;	# IPv4
	$rhs = sprintf '%x%0.2x:%x%0.2x', map { $_ || 0 } split( /\./, $rhs, 4 ) if /\./;
	$address =~ s/:[^:]*$/:0$rhs/;
	my @parse = split /:/, ( reverse "0$address" ), 9;
	my @xpand = map { /./ ? $_ : ('0') x ( 9 - @parse ) } @parse;	 # expand ::
	$pfxlen = ( scalar(@xpand) << 4 ) unless $pfxlen;	# implicit length if unspecified
	my $len = $pfxlen > 124 ? 32 : ( $pfxlen + 3 ) >> 2;
	my $hex = pack 'A4' x 8, map { $_ . '000' } ('0') x ( 8 - @xpand ), @xpand;
	return join '.', split( //, substr( $hex, -$len ) ), 'ip6.arpa.';
}


1;
__END__

########################################

=head1 COPYRIGHT

Copyright (c)1997-2000 Michael Fuhr. 

Portions Copyright (c)2002,2003 Chris Reinhardt.

Portions Copyright (c)2003,2006-2011 Dick Franks.

All rights reserved.


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

L<perl> L<Net::DNS> L<Net::DNS::DomainName> L<Net::DNS::Packet>
L<RFC1035(4.1.2)|https://iana.org/go/rfc1035#section-4.1.2>

=cut

