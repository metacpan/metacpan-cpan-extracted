package Net::DNS::Resolver::Unbound;

use strict;
use warnings;

our $VERSION;
$VERSION = '1.11';

use Carp;
use Net::DNS;

use base qw(Net::DNS::Resolver DynaLoader);
eval { __PACKAGE__->bootstrap($VERSION) };
warn "\n\n$@\n" if $@;


=head1 NAME

Net::DNS::Resolver::Unbound - Unbound resolver base for Net::DNS

=head1 SYNOPSIS

    use Net::DNS;
    use Net::DNS::Resolver::Unbound;
    my $resolver = Net::DNS::Resolver::Unbound->new(...);
    my $response = $resolver->send(...);

=head1 DESCRIPTION

Net::DNS::Resolver::Unbound is designed as an extension to an existing
Net::DNS installation which facilitates DNS(SEC) name resolution.

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


=head1 METHODS

=head2 new

    my $resolver = Net::DNS::Resolver::Unbound->new(
	debug_level => 2,
	defnames    => 1,
	dnsrch,	    => 1,
	domain	    => 'domain',
	ndots	    => 1,
	searchlist  => ['domain' ... ],
	nameservers => [ ... ],
	option => ['logfile', 'mylog.txt'] );

Returns a new Net::DNS::Resolver::Unbound resolver object.

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


=head2 nameservers

    my $stub_resolver = Net::DNS::Resolver::Unbound->new(
	nameservers => [ '127.0.0.53' ]
	);

    my $fully_recursive = Net::DNS::Resolver::Unbound->new(
	nameservers => [],		# override /etc/resolv.conf
	);

By default, DNS queries are sent to the IP addresses listed in
/etc/resolv.conf or similar platform-specific sources.


=head2 search, query, send, bgsend, bgbusy, bgread

See L<Net::DNS::Resolver>.

=cut

sub send {
	my $self = shift;
	$self->_finalise_config;
	$self->_reset_errorstring;

	my ($query) = $self->_make_query_packet(@_)->question;
	my $result = $self->{ub_ctx}->ub_resolve( $query->name, $query->{qtype}, $query->{qclass} );
	return $self->_decode_result($result);
}

sub bgsend {
	my $self = shift;
	$self->_finalise_config;
	$self->_reset_errorstring;

	my ($query) = $self->_make_query_packet(@_)->question;
	return $self->{ub_ctx}->ub_resolve_async( $query->name, $query->{qtype}, $query->{qclass} );
}

sub bgbusy {
	my ( $self, $handle ) = @_;
	return unless $handle;
	return unless $handle->waiting;
	$self->{ub_ctx}->ub_process;
	eval { select( undef, undef, undef, 0.200 ) };		# avoid tight loop on bgbusy()
	return $handle->waiting;
}

sub bgread {
	my ( $self, $handle ) = @_;
	return unless $handle;

	$self->{ub_ctx}->ub_wait if &bgbusy;

	my $async_id = $handle->async_id;
	$self->errorstring( $handle->err );
	my $result = $handle->result;
	return $self->_decode_result($result);
}


=head2 option

    $filename = $resolver->option( 'logfile' );
    $resolver->option( 'logfile', $filename );

Get or set Unbound resolver (name,value) context options.

=cut

sub option {
	my ( $self, $name, @value ) = @_;
	return $self->{ub_ctx}->set_option( "$name:", @value ) if @value;
	my $value = $self->{ub_ctx}->get_option($name);
	return wantarray ? split /\r*\n/, $value : $value;
}


=head2 config

    $resolver->config( 'Unbound.cfg' );

This is a power-users interface that lets you specify all sorts of
Unbound configuration options.

=cut

sub config {
	my ( $self, $filename ) = @_;
	return $self->{ub_ctx}->config($filename);
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
	my ( $self, $fwd ) = @_;
	return $self->{ub_ctx}->set_fwd($fwd);
}


=head2 set_tls

    $resolver->set_tls( 0 );
    $resolver->set_tls( 1 );

Use DNS over TLS to send queries to machines specified using set_fwd().

=cut

sub set_tls {
	my ( $self, $do_tls ) = @_;
	return $self->{ub_ctx}->set_tls($do_tls);
}


=head2 set_stub

    $resolver->set_stub( 'zone', '10.1.2.3', 0 );

Add a stub zone, with given address to send to. This is for custom root
hints or pointing to a local authoritative dns server. For dns resolvers
and the 'DHCP DNS' ip address, use ub_ctx_set_fwd.

=cut

sub set_stub {
	my ( $self, $zone, $address, $prime ) = @_;
	return $self->{ub_ctx}->set_stub( $zone, $address, $prime );
}


=head2 resolv_conf

    $resolver->resolv_conf( 'filename' );

Extract nameserver list from resolv.conf(5) format configuration file.
Any domain, searchlist, ndots or other settings are ignored.

Note that Net::DNS builds its own nameserver list using /etc/resolv.conf
or other platform-specific sources.

=cut

sub resolv_conf {
	my ( $self, $filename ) = @_;
	return $self->{ub_ctx}->resolv_conf($filename);
}


=head2 hosts

    $resolver->hosts( 'filename' );

Read list of hosts from the filename given, usually "/etc/hosts".
These addresses are not flagged as DNSSEC secure when queried.

=cut

sub hosts {
	my ( $self, $filename ) = @_;
	return $self->{ub_ctx}->hosts($filename);
}


=head2 add_ta

    $resolver->add_ta( 'trust anchor' );

Add a trust anchor which is a string that holds a valid DNSKEY or DS RR
in RFC1035 zonefile format.

=cut

sub add_ta {
	my $self = shift;
	return $self->{ub_ctx}->add_ta( Net::DNS::RR->new(@_)->plain );
}


=head2 add_ta_file

    $resolver->add_ta_file( 'filename' );

Pass the name of a file containing DS and DNSKEY records
(as from dig or drill).

=cut

sub add_ta_file {
	my ( $self, $filename ) = @_;
	return $self->{ub_ctx}->add_ta_file($filename);
}


=head2 add_ta_autr

    $resolver->add_ta_autr( 'filename' );

Add trust anchor to the given context that is tracked with RFC5011
automated trust anchor maintenance.  The file is written when the
trust anchor is changed.

=cut

sub add_ta_autr {
	my ( $self, $filename ) = @_;
	return $self->{ub_ctx}->add_ta_autr($filename);
}


=head2 trusted_keys

    $resolver->trusted_keys( 'filename' );

Pass the name of a bind-style config file containing trusted-keys{}.

=cut

sub trusted_keys {
	my ( $self, $filename ) = @_;
	return $self->{ub_ctx}->trusted_keys($filename);
}


=head2 debug_out

    $resolver->debug_out( out );

Send debug output (and error output) to the specified stream.
Pass a null argument to disable. Default is stderr.

=cut

sub debug_out {
	my ( $self, $out ) = @_;
	return $self->{ub_ctx}->debug_out($out);
}


=head2 debug_level

    $resolver->debug_level(0);

Set verbosity of the debug output directed to stderr.  Level 0 is off,
1 minimal, 2 detailed, 3 lots, and 4 lots more.

=cut

sub debug_level {
	my ( $self, $verbosity ) = @_;
	$self->debug($verbosity);
	return $self->{ub_ctx}->debug_level($verbosity);
}


=head2 async_thread

    $resolver->async_thread(1);

Enable a call to resolve_async() to create a thread to handle work in
the background. If false (by default), a process is forked to perform
the work.

=cut

sub async_thread {
	my ( $self, $dothread ) = @_;
	return $self->{ub_ctx}->async($dothread);
}


########################################

sub nameservers {
	my $self = shift;
	local $self->{debug};		## "no nameservers" ok in this context
	return $self->SUPER::nameservers(@_);
}

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
		$self->errorstring('INSECURE') unless $result->secure;
		$self->errorstring( $result->why_bogus ) if $result->bogus;

		my $buffer = $result->answer_packet;
		$packet = Net::DNS::Packet->decode( \$buffer, $self->debug );
		$self->errorstring($@);
	}

	return $packet;
}


sub _finalise_config {
	my $self = shift;
	return if $self->{ub_frozen}++;

	my %IP_conf = (
		force_v4  => ['do-ip6'	   => 'no'],
		force_v6  => ['do-ip4'	   => 'no'],
		prefer_v4 => ['prefer-ip4' => 'yes'],
		prefer_v6 => ['prefer-ip6' => 'yes'] );

	for ( grep { $self->{$_} } qw(prefer_v4 prefer_v6 force_v4 force_v6) ) {
		my $argref = $IP_conf{$_};
		eval { $self->option(@$argref) };		# unimplemented in old versions
	}

	my $count = 3;
	foreach ( grep { $count-- > 0 } $self->nameservers ) {
		$self->set_fwd($_);
	}
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

