package Net::DNS::Resolver::Unbound;

use strict;
use warnings;

our $VERSION;
$VERSION = '1.05';

=head1 NAME

Net::DNS::Resolver::Unbound - Unbound resolver base for Net::DNS

=head1 SYNOPSIS

    use Net::DNS;
    use Net::DNS::Resolver::Unbound;
    my $resolver = Net::DNS::Resolver::Unbound->new(...);
    my $response = $resolver->send(...);

=head1 DESCRIPTION

Net::DNS::Resolver::Unbound is designed as an extension to an existing
Net::DNS installation which provides DNSSEC validated name resolution.

Net::DNS::Resolver::Unbound replaces the resolver send() and bgsend()
functionality in the Net::DNS::Resolver::Base implementation.

As of this writing, the implementation has some significant limitations:

=over 3

=item *

Selection of transport protocol and associated parameters is entirely
at the discretion of Unbound.

=item *

There is no provision for specifying DNS header flags or EDNS options
in outbound packets.

=item *

It is not possible to send a pre-constructed DNS query packet to a
nameserver. A best-effort attempt is made using (qname,qtype,qclass)
extracted from the presented packet.

=back

=cut


use Carp;
use Net::DNS;
use base qw(Net::DNS::Resolver DynaLoader);

eval { Net::DNS::Resolver::Unbound->bootstrap($VERSION) } || croak $@;


=head1 METHODS

=head2 new

    my $resolver = Net::DNS::Resolver::Unbound->new(
	debug	    => 1,
	defnames    => 1,
	dnsrch,	    => 1,
	domain	    => 'domain',
	ndots	    => 1,
	searchlist  => ['domain' ... ],
	nameservers => [ ... ],
	option => ['logfile', 'mylog.txt'] );

Returns a new Net::DNS::Resolver::Unbound resolver object.


=head2 nameservers, force_v6, prefer_v6, force_v4, prefer_v4

See L<Net::DNS::Resolver>.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{ub_ctx} = Net::DNS::Resolver::Unbound::Context->new();
	while ( my $attr = shift ) {
		my $value = shift;
		my $ref	  = ref($value);
		croak "usage: $class->new( $attr => [...] )"
				if $ref && ( $ref ne 'ARRAY' );
		$self->$attr( $ref ? @$value : $value );
	}
	return $self;
}


=head2 search, query, send, bgsend, bgbusy, bgread

See L<Net::DNS::Resolver>.

=cut

sub send {
	my $self = shift;
	$self->_finalise_config;
	$self->_reset_errorstring;

	my ($query) = $self->_make_query_packet(@_)->question;
	my $qname   = $query->name;
	my $qtype   = $query->{qtype};
	my $qclass  = $query->{qclass};

	my $ub_ctx = $self->{ub_ctx};
	my $result = eval {
		my $ub_result = Net::DNS::Resolver::libunbound::ub_resolve( $ub_ctx, $qname, $qtype, $qclass );
		bless( $ub_result, 'Net::DNS::Resolver::Unbound::Result' );
	};
	$self->errorstring($@);
	return $self->_decode_result($result);
}

sub bgsend {
	my $self = shift;
	$self->_finalise_config;
	$self->_reset_errorstring;

	my ($query) = $self->_make_query_packet(@_)->question;
	my $qname   = $query->name;
	my $qtype   = $query->{qtype};
	my $qclass  = $query->{qclass};

	my $handle = [];
	my $ub_ctx = $self->{ub_ctx};
	eval { Net::DNS::Resolver::libunbound::ub_resolve_async( $ub_ctx, $qname, $qtype, $qclass, $handle ) };
	$self->errorstring($@);
	return $handle;
}

sub bgbusy {
	my ( $self, $handle ) = @_;
	return unless $handle;
	my ( undef, @pre ) = @$handle;
	return if scalar(@pre);
	my $ub_ctx = $self->{ub_ctx};
	eval { Net::DNS::Resolver::libunbound::ub_process($ub_ctx) };
	$self->errorstring($@);
	eval { select( undef, undef, undef, 0.500 ) };		# avoid tight loop on bgbusy()
	my ( undef, @post ) = @$handle;
	return scalar(@post) ? 0 : 1;
}

sub bgread {
	my ( $self, $handle ) = @_;

	my $ub_ctx = $self->{ub_ctx};
	eval { Net::DNS::Resolver::libunbound::ub_wait($ub_ctx) } if &bgbusy;
	$self->errorstring($@);

	return unless $handle;
	my ( $async_id, $err, $result ) = @$handle;
	$self->errorstring( Net::DNS::Resolver::libunbound::ub_strerror($err) ) if $err;
	return $self->_decode_result($result);
}


=head2 option

    $filename = $resolver->option( 'logfile' );
    $resolver->option( 'logfile', $filename );

Get or set Unbound resolver (name,value) context options.

=cut

sub option {
	my ( $self, $name, @value ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_set_option( $ctx, "$name:", @value ) if @value;
	my $value = Net::DNS::Resolver::libunbound::ub_ctx_get_option( $ctx, $name );
	return wantarray ? split /\r*\n/, $value : $value;
}


=head2 config

    $resolver->config( 'Unbound.cfg' );

This is a power-users interface that lets you specify all sorts of
Unbound configuration options.

=cut

sub config {
	my ( $self, $filename ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_config( $ctx, $filename );
}


=head2 set_fwd

    $resolver->set_fwd( 'IP address' );

Set IPv4 or IPv6 address to which DNS queries are to be directed.
The destination machine is expected to run a recursive resolver.
If the proxy is not DNSSEC-capable, validation may fail.
Can be called several times, in that case the addresses are used
as backup servers.


=cut

sub set_fwd {
	my ( $self, $address ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_set_fwd( $ctx, $address || return );
}


=head2 set_tls

    $resolver->set_tls( 0 );
    $resolver->set_tls( 1 );

Use DNS over TLS to send queries to machines specified using set_fwd().

=cut

sub set_tls {
	my ( $self, $boolean ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_set_tls( $ctx, $boolean );
}


=head2 set_stub

    $resolver->set_stub( 'zone', '10.1.2.3', 0 );

Add a stub zone, with given address to send to. This is for custom root
hints or pointing to a local authoritative dns server. For dns resolvers
and the 'DHCP DNS' ip address, use ub_ctx_set_fwd.

=cut

sub set_stub {
	my ( $self, $zone, $address, $prime ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_set_stub( $ctx, $zone, $address, $prime );
}


=head2 resolvconf

    $resolver->resolvconf( 'filename' );

Extract nameserver list from resolv.conf(5) format configuration file.
Any domain, searchlist, ndots or other settings are ignored.
Note that Net::DNS builds its own nameserver list using /etc/resolv.conf
or other platform-specific sources.

=cut

sub resolvconf {
	my ( $self, $filename ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_resolvconf( $ctx, $filename );
}

=head2 hosts

    $resolver->hosts( 'filename' );

Read list of hosts from the filename given, usually "/etc/hosts".
These addresses are not flagged as DNSSEC secure when queried.

=cut

sub hosts {
	my ( $self, $filename ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_hosts( $ctx, $filename );
}


=head2 add_ta

    $resolver->add_ta( 'trust anchor' );

Add a trust anchor which is a string that holds a valid DNSKEY or DS RR
in RFC1035 zonefile format.

=cut

sub add_ta {
	my $self = shift;
	my $ta	 = Net::DNS::RR->new(@_);
	my $ctx  = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_add_ta( $ctx, $ta->plain );
}

=head2 add_ta_file

    $resolver->add_ta_file( 'filename' );

Pass the name of a file containing DS and DNSKEY records (like from dig
or drill).

=cut

sub add_ta_file {
	my ( $self, $filename ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_add_ta_file( $ctx, $filename );
}

=head2 add_ta_autr

    $resolver->add_ta_autr( 'filename' );

Add trust anchor to the given context that is tracked with RFC5011
automated trust anchor maintenance.  The file is written when the
trust anchor is changed.

=cut

sub add_ta_autr {
	my ( $self, $filename ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_add_ta_autr( $ctx, $filename );
}

=head2 trustedkeys

    $resolver->trustedkeys( 'filename' );

Pass the name of a bind-style config file comtaining trusted-keys{}.

=cut

sub trustedkeys {
	my ( $self, $filename ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_trustedkeys( $ctx, $filename );
}


=head2 debugout

    $resolver->debugout( out );

Send debug output (and error output) to the specified stream.
Pass a null argument to disable. Default is stderr.

=cut

sub debugout {
	my ( $self, $out ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_debugout( $ctx, $out );
}

=head2 debug_level

    $resolver->debug_level(0);

Set verbosity of the debug output directed to stderr.  Level 0 is off,
1 very minimal, 2 detailed, and 3 lots.

=cut

sub debug_level {
	my ( $self, $verbosity ) = @_;
	$self->debug($verbosity);
	Net::DNS::Resolver::libunbound::ub_ctx_debuglevel( $self->{ub_ctx}, $verbosity );
	return;
}


=head2 async_thread

    $resolver->async_thread(1);

Enable a call to resolve_async() to create a thread to handle work in
the background. If false (by default), a process is forked to handle
work in the background.

=cut

sub async_thread {
	my ( $self, $dothread ) = @_;
	Net::DNS::Resolver::libunbound::ub_ctx_async( $self->{ub_ctx}, $dothread );
	return;
}


########################################

sub replyfrom { return "(local) Unbound resolver" }

sub string {
	my $self = shift;

	$self = $self->_defaults unless ref($self);

	my @nslist   = $self->nameservers();
	my ($force)  = ( grep( { $self->{$_} } qw(force_v6 force_v4) ),	  'force_v4' );
	my ($prefer) = ( grep( { $self->{$_} } qw(prefer_v6 prefer_v4) ), 'prefer_v4' );
	return <<END;
;; RESOLVER state:
;; nameservers	= @nslist
;; searchlist	= @{$self->{searchlist}}
;; defnames	= $self->{defnames}	dnsrch		= $self->{dnsrch}
;; ${prefer}	= $self->{$prefer}	${force}	= $self->{$force}
;; debug	= $self->{debug}	ndots		= $self->{ndots}
END
}

sub print {
	return print shift->string;
}


sub _decode_result {
	my ( $self, $result ) = @_;

	my $packet;
	if ($result) {
		my $buffer = Net::DNS::Resolver::libunbound::ub_result_packet($result);
		$packet = Net::DNS::Packet->decode( \$buffer, $self->debug );
		$self->errorstring($@);
	}

	$packet->from( $self->replyfrom ) if $packet;
	return $packet;
}


sub _finalise_config {
	my $self = shift;
	return if $self->{ub_frozen}++;
	my @nameservers = $self->nameservers;
	$self->set_fwd( shift @nameservers );
	$self->set_fwd( shift @nameservers );
	$self->set_fwd( shift @nameservers );
	return;
}


1;
__END__


=head1 COPYRIGHT

Copyright (c)2022 Dick Franks

All Rights Reserved


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

L<perl>, L<Net::DNS>, L<Net::DNS::Resolver>,
L<Unbound|https://unbound.docs.nlnetlabs.nl/en/latest>

=cut

