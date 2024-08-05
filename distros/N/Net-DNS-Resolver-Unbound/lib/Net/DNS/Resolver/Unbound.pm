package Net::DNS::Resolver::Unbound;

use strict;
use warnings;
use integer;
use Net::DNS;

use constant OS_SPEC => defined eval "require Net::DNS::Resolver::$^O";	## no critic
use constant OS_CONF => join '::', 'Net::DNS::Resolver', OS_SPEC ? $^O : 'UNIX';
use base qw(Net::DNS::Resolver::Base DynaLoader), OS_CONF;

our $VERSION;

BEGIN {
	$VERSION = '1.28';
	eval { __PACKAGE__->bootstrap($VERSION) };
}

use constant UB_VERSION => scalar eval {
	my $version = Net::DNS::Resolver::libunbound->VERSION();
	my ( $major, $minor, $minimus ) = split /\D/, $version;
	( $major * 100 + $minor ) * 100 + $minimus;
};

use constant UB_CONTEXT => 'Net::DNS::Resolver::Unbound::Context';
use constant IRRELEVENT => qw(igntc nameserver4 nameserver6 nameservers
		persistent_tcp persistent_udp port retrans retry
		srcaddr4 srcaddr6 srcport tcp_timeout udp_timeout usevc);

use constant IP_PREF	 => UB_VERSION > 11100;
use constant ADD_TA_AUTR => UB_CONTEXT->can('add_ta_autr');
use constant SET_STUB	 => UB_CONTEXT->can('set_stub');
use constant SET_TLS	 => UB_CONTEXT->can('set_tls');


=head1 NAME

Net::DNS::Resolver::Unbound - Net::DNS resolver based on libunbound

=head1 SYNOPSIS

    use Net::DNS;
    use Net::DNS::Resolver::Unbound;
    my $resolver = Net::DNS::Resolver::Unbound->new(...);
    my $response = $resolver->send(...);

=head1 DESCRIPTION

Net::DNS::Resolver::Unbound is designed as an extension to an existing
Net::DNS installation which facilitates DNS(SEC) name resolution using
the libunbound library developed by NLnet Labs.

Net::DNS::Resolver::Unbound replaces the resolver send() and bgsend()
functionality in the Net::DNS::Resolver::Base implementation.

As of this writing, the implementation has some significant limitations:

=over 3

=item *

Selection of transport protocol and associated parameters is almost
entirely at the discretion of Unbound.

=item *

There is no provision for specifying DNS header flags or EDNS options
in outbound packets.

=item *

It is not possible to send a pre-constructed packet to a nameserver.
A best-effort attempt is made instead using (qname,qtype,qclass)
extracted from the presented packet.

=item *

Result packet is synthesised in libunbound and not the "real thing".
In particular, the queryID returned by Unbound is always zero.

=back


=head1 METHODS

=head2 new

    my $resolver = Net::DNS::Resolver::Unbound->new(
	debug_level => 2,
	defnames    => 1,
	dnsrch,	    => 1,
	domain	    => 'domain',
	ndots	    => 1,
	option	    => [ 'tls-cert-bundle', '/etc/ssl/cert.pem' ],
	nameservers => [ ... ],
	searchlist  => ['domain' ... ],
	);

Returns a new Net::DNS::Resolver::Unbound resolver object.

=cut

sub new {
	my ( $class, @args ) = @_;
	my $self = $class->SUPER::new();
	$self->nameservers( $self->SUPER::nameservers );
	delete $self->{$_} for IRRELEVENT;
	$self->_finalise_config;				# default configuration
	$self->{update} = {} if @args;				# force context rebuild
	while ( my $attr = shift @args ) {
		my $value = shift @args;
		$self->$attr( ref($value) ? @$value : $value );
	}
	return $self;
}


=head2 nameservers

    my $stub_resolver = Net::DNS::Resolver::Unbound->new(
	nameserver => '127.0.0.53'
	);

    my $fully_recursive = Net::DNS::Resolver::Unbound->new(
	nameservers => [],		# override /etc/resolv.conf
	add_ta_file => '/var/lib/unbound/root.key'
	);

    my $DoT_resolver = Net::DNS::Resolver->new(
	nameserver => '2606:4700:4700::1111@853#cloudflare-dns.com',
	nameserver => '2001:4860:4860::8888@853#dns.google',
	nameserver => '8.8.8.8@853#dns.google',
	nameserver => '9.9.9.9@853#dns.quad9.net',
	option	   => [qw(tls-cert-bundle /etc/ssl/cert.pem)],
	set_tls	   => 1
	);

    $resolver->nameservers( '::1', '127.0.0.1', ... );
    @nameservers = $resolver->nameservers;

By default, DNS queries are sent to the IP addresses listed in
/etc/resolv.conf or similar platform-specific sources.

=cut

sub nameservers {
	my ( $self, @nameservers ) = @_;
	if ( defined wantarray ) {
		my $config   = $self->{config};
		my $update   = $self->{update};
		my @setfwd   = ( $update->{set_fwd}, $config->{set_fwd}, [] );
		my ($setfwd) = grep { defined $_ } @setfwd;
		my @value    = map { ref($_) ? @$_ : $_ } $setfwd;
		return @value;
	}
	$self->set_fwd() unless @nameservers;
	$self->set_fwd($_) foreach @nameservers;
	return;
}

sub nameserver { &nameservers; }


=head2 search, query, send, bgsend, bgbusy, bgread

See L<Net::DNS::Resolver>.

=cut

use constant UB_SEND => UB_CONTEXT->can('ub_send');

sub send {
	my ( $self, @argument ) = @_;

	my ($packet) = @argument;
	if ( ref $packet ) {					# resolve packets asynchronously
		my $handle = $self->bgsend(@argument);
		return $self->bgread($handle);
	}

	$self->_finalise_config;
	$self->_reset_errorstring;

	my $query  = $self->_make_query_packet(@argument);
	my ($q)	   = $query->question;
	my $result = $self->{ub_ctx}->ub_resolve( $q->name, $q->{qtype}, $q->{qclass} );
	return $self->_decode_result($result);
}

sub bgsend {
	my ( $self, @argument ) = @_;
	$self->_finalise_config;
	$self->_reset_errorstring;

	my $query = $self->_make_query_packet(@argument);
	my $image = $query->encode;
	my $ident = $query->header->id;
	my ($q)	  = $query->question;
	return $self->{ub_ctx}->ub_resolve_async( $q->name, $q->{qtype}, $q->{qclass}, $ident );
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

	$self->{ub_ctx}->ub_wait;
	$self->errorstring( $handle->err );

	my $reply = $self->_decode_result( $handle->result ) || return;
	$reply->header->id( $handle->query_id );		# lying toad!;
	return $reply;
}


=head2 option

    $resolver->option( 'tls-cert-bundle', '/etc/ssl/cert.pem' );

Set Unbound resolver (name,value) context option.

=cut

sub option {
	my ( $self, $name, @value ) = @_;
	return $self->_option( $name, @value );
}


=head2 config

    $resolver->config( 'Unbound.cfg' );

This is a power-users interface that lets you specify all sorts of
Unbound configuration options.

=cut

sub config {
	my ( $self, $filename ) = @_;
	return $self->_config( 'config', $filename );
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
	my ( $self, @fwd ) = @_;
	return $self->_config( 'set_fwd', @fwd );
}


=head2 set_tls

    $resolver->set_tls( 0 );
    $resolver->set_tls( 1 );

Use DNS over TLS for queries to nameservers specified using set_fwd().

=cut

sub set_tls {
	my ( $self, $tls ) = @_;
	return SET_TLS ? $self->_config( 'set_tls', $tls ) : undef;
}


=head2 set_stub

    $resolver->set_stub( 'zone', '10.1.2.3', 0 );

Add a stub zone, with given address to send to. This is for custom root
hints or pointing to a local authoritative DNS server. For DNS resolvers
and the 'DHCP DNS' IP address, use set_fwd().

=cut

sub set_stub {
	my ( $self, $zone, $address, $prime ) = @_;
	return SET_STUB ? $self->_config( 'set_stub', $zone, $address, $prime ) : undef;
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
	return $self->_config( 'resolvconf', $filename );
}


=head2 hosts

    $resolver->hosts( 'filename' );

Read list of hosts from the filename given, usually "/etc/hosts".
These addresses are not flagged as DNSSEC secure when queried.

=cut

sub hosts {
	my ( $self, $filename ) = @_;
	return $self->_config( 'hosts', $filename );
}


=head2 add_ta

    $resolver->add_ta( 'trust anchor' );

Add a trust anchor which is a string that holds a valid DNSKEY or DS RR
in RFC1035 zonefile format.

=cut

sub add_ta {
	my ( $self, @argument ) = @_;
	my $ta = Net::DNS::RR->new(@argument)->plain;
	return $self->_config( 'add_ta', $ta );
}


=head2 add_ta_file

    $resolver->add_ta_file( 'filename' );

Pass the name of a file containing DS and DNSKEY records
(as from dig or drill).

=cut

sub add_ta_file {
	my ( $self, $filename ) = @_;
	return $self->_config( 'add_ta_file', $filename );
}


=head2 add_ta_autr

    $resolver->add_ta_autr( 'filename' );

Add trust anchor to the given context that is tracked with RFC5011
automated trust anchor maintenance.  The file is written when the
trust anchor is changed.

=cut

sub add_ta_autr {
	my ( $self, $filename ) = @_;
	return ADD_TA_AUTR ? $self->_config( 'add_ta_autr', $filename ) : undef;
}


=head2 trusted_keys

    $resolver->trusted_keys( 'filename' );

Pass the name of a BIND-style config file containing trusted-keys{}.

=cut

sub trusted_keys {
	my ( $self, $filename ) = @_;
	return $self->_config( 'trustedkeys', $filename );
}


=head2 debug_out

    $resolver->debug_out( out );

Send debug output (and error output) to the specified stream.
Pass a null argument to disable. Default is stderr.

=cut

sub debug_out {
	my ( $self, $stream ) = @_;
	return $self->_config( 'debugout', $stream );
}


=head2 debug_level

    $resolver->debug_level(0);

Set verbosity of the debug output directed to stderr.  Level 0 is off,
1 minimal, 2 detailed, 3 lots, and 4 lots more.

=cut

sub debug_level {
	my ( $self, $verbosity ) = @_;
	$self->debug($verbosity);
	return $self->_config( 'debuglevel', $verbosity );
}


=head2 async_thread

    $resolver->async_thread(1);

Set the context behaviour for asynchronous actions.
Enable a call to resolve_async() to create a thread to handle work in
the background.
If false (by default), a process is forked to perform the work.

=cut

sub async_thread {
	my ( $self, $threaded ) = @_;
	return $self->_config( 'async', $threaded );
}


=head2 print, string

    $resolver->print;
    print $resolver->string;

Prints the resolver state on the standard output.

=cut

sub string {
	my $self = shift;
	$self = $self->new() unless ref($self);

	my ($force)  = ( grep( { $self->{$_} } qw(force_v6 force_v4) ),	  'force_v4' );
	my ($prefer) = ( grep( { $self->{$_} } qw(prefer_v6 prefer_v4) ), 'prefer_v4' );
	my $image    = <<END;
;; RESOLVER state:
;; searchlist	@{$self->{searchlist}}
;; defnames	$self->{defnames}	dnsrch	$self->{dnsrch}
;; ${prefer}	$self->{$prefer}	ndots	$self->{ndots}
;; ${force}	$self->{$force}	debug	$self->{debug}
END
	$self->{update} ||= {};					# force config rebuild
	$self->_finalise_config;
	my %config = %{$self->{config}};
	my $optref = $config{set_option} || [];
	my @option = @$optref;					# pre-sorted option list

	my @expand;
	while ( my $name = shift @option ) {			# expand option list
		foreach my $value ( map { ref($_) ? @$_ : $_ } shift @option ) {
			push @expand, [$name, $value];
		}
	}

	my $format = ";; %s\t%s\n";
	local $config{set_option} = \@expand;
	foreach my $name ( sort keys %config ) {
		my $value = $config{$name};
		if ( ref $value ) {
			foreach my $arg (@$value) {
				my @arg = map { ref($_) ? @$_ : $_ } $arg;
				$image .= sprintf( $format, $name, join ' ', @arg );
			}
		} else {
			$image .= sprintf( $format, $name, $value );
		}
	}
	return $image;
}


########################################

sub _decode_result {
	my ( $self, $result ) = @_;

	return unless $result;

	$self->errorstring('INSECURE') unless $result->secure;
	$self->errorstring( $result->why_bogus ) if $result->bogus;

	my $buffer = $result->answer_packet || return;
	my $packet = Net::DNS::Packet->decode( \$buffer );
	$self->errorstring($@);
	$packet->print if $self->debug;

	return $packet;
}


sub _config {
	my ( $self, $name, @arg ) = @_;
	my $entry = ( scalar(@arg) == 1 ) ? $arg[0] : [@arg];
	my $ctx	  = $self->{test_ctx};
	$self->{test_ctx} = $ctx = Net::DNS::Resolver::Unbound::Context->new() unless $ctx;
	$ctx->$name(@arg) if @arg;				# error check only
	my $state = $self->{update}->{$name};
	if ( defined $state ) {					# second and subsequent entries
		$state = $self->{update}->{$name} = [$state] unless ref $state;
		push @$state, $entry;
	} else {						# initial entry
		$self->{update}->{$name} = ( scalar(@arg) > 1 ) ? [$entry] : $entry;
	}
	return;
}


sub _option {
	my ( $self, $name, @arg ) = @_;
	my ($entry) = @arg;
	my $opt	    = "${name}:";
	my $ctx	    = $self->{test_ctx};
	$self->{test_ctx} = $ctx = Net::DNS::Resolver::Unbound::Context->new() unless $ctx;
	$ctx->set_option( $opt, @arg ) if defined $entry;	# error check only
	my $updopt = $self->{update}->{set_option};
	my %option = map {$_} @$updopt;

	unless (@arg) {
		my $setopt = $self->{config}->{set_option};
		my %config = map {$_} @$setopt, @$updopt;
		my $value  = $config{$opt};
		return ref($value) ? @$value : $value;
	}

	my $state = $option{$opt};
	if ( defined $state ) {					# second and subsequent entries
		$option{$opt} = $state = [$state] unless ref $state;
		push @$state, $entry;
	} else {						# initial entry
		$option{$opt} = $entry;
	}

	$option{$opt} = [] unless defined $entry;		# delete entire option
	my @option = map { ( $_, $option{$_} ) } keys %option;
	$self->{update}->{set_option} = \@option;
	return;
}


my %IP_conf = (
	force_v4  => ['do-ip6:'	    => 'no'],
	force_v6  => ['do-ip4:'	    => 'no'],
	prefer_v4 => ['prefer-ip4:' => 'yes'],
	prefer_v6 => ['prefer-ip6:' => 'yes'] );
my @IPpref = map {@$_} values %IP_conf;
delete @IP_conf{qw(prefer_v4 prefer_v6)} unless IP_PREF;
my @IPconf = sort keys %IP_conf;

sub _finalise_config {
	my $self = shift;

	my $update = delete $self->{update};
	return unless $update;
	delete $self->{test_ctx};
	delete $self->{ub_ctx};

	my $config = $self->{config};
	my $cfgopt = delete $config->{set_option};		# extract option lists
	my $updopt = delete $update->{set_option};
	my %config = ( %$config, %$update );			# merge config updates

	my %option = map {$_} @$cfgopt, @$updopt;		# merge option updates
	delete @option{@IPpref};				# expunge IP preference
	foreach my $key ( grep { $self->$_ } @IPconf ) {	# insert IP preference
		my ( $key, $value ) = @{$IP_conf{$key}};
		$option{$key} = $value;
		last;
	}
	my @option = map { ( $_, $option{$_} ) } sort keys %option;    # rebuild option list

	my $ctx = $self->{ub_ctx} = Net::DNS::Resolver::Unbound::Context->new();
	foreach my $name ( keys %option ) {			# set unbound options
		foreach my $value ( map { ref($_) ? @$_ : $_ } $option{$name} ) {
			$ctx->set_option( $name, $value );
		}
	}

	foreach my $name ( keys %config ) {			# rebuild unbound context
		foreach my $value ( map { ref($_) ? @$_ : $_ } $config{$name} ) {
			my @arg = map { ref($_) ? @$_ : $_ } $value;
			$ctx->$name(@arg);
		}
	}

	$config{set_option} = \@option if @option;
	$self->{config} = \%config;
	return;
}


1;
__END__


=head1 COPYRIGHT

Copyright (c)2022,2024 Dick Franks

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
L<Unbound|https://www.nlnetlabs.nl/projects/unbound/>

=cut

