package Net::DNSBL::Client;
use strict;
use warnings;
use 5.008;

use Carp;
use Net::DNS::Resolver;
use IO::Select;

our $VERSION = '0.207';

=head1 NAME

Net::DNSBL::Client - Client code for querying multiple DNSBLs

=head1 SYNOPSIS

    use Net::DNSBL::Client;
    my $c = Net::DNSBL::Client->new({ timeout => 3 });

    $c->query_ip('127.0.0.2', [
            { domain => 'simple.dnsbl.tld' },
            { domain => 'masked.dnsbl.tld', type => 'mask', data => '0.0.0.255' },
            { domain => 'txt.dnsbl.tld', type => 'txt' },
            { domain => 'need-a-key.example.net' }],
        { lookup_keys => { 'need-a-key.example.net' => 'my_secret_key' }});

    # And later...
    my $answers = $c->get_answers();

=head1 METHODS

=head2 Class Methods

=over 4

=item new ( $args )

Returns a new Net::DNSBL::Client object.

$args is a hash reference and may contain the following key-value pairs:

=over 4

=item resolver

(optional) A Net::DNS::Resolver object.  If not provided, a new resolver will be created.

=item timeout

(optional) An integer number of seconds to use as the upper time limit
for the query.  If not provided, the default is 10 seconds.  If provided,
timeout must be a I<positive> integer.

=back

=back

=cut

sub new
{
	my ($class, $args) = @_;
	my $self = {
		resolver   => undef,
		timeout    => 10,
	};
	foreach my $possible_arg (keys(%$self)) {
		if( exists $args->{$possible_arg} ) {
			$self->{$possible_arg} = delete $args->{$possible_arg};
		}
	}
	if (scalar(%$args)) {
		croak("Unknown arguments to new: " .
		      join(', ', (sort { $a cmp $b } keys(%$args))));
	}

	# Timeout must be a positive integer
	if (($self->{timeout} !~ /^\d+$/) || $self->{timeout} <= 0) {
		croak("Timeout must be a positive integer");
	}

	$self->{resolver} = Net::DNS::Resolver->new() unless $self->{resolver};

	$self->{in_flight} = 0;
	$self->{early_exit} = 0;

	bless $self, $class;
	return $self;
}

sub _matches
{
	my ($self, $addr, $match) = @_;
	my ($a1, $b1, $c1, $d1) = split(/\./, $addr);
	my ($a2, $b2, $c2, $d2) = split(/\./, lc($match));

	return (
		($a2 eq 'x' || $a1 == $a2) &&
		($b2 eq 'x' || $b1 == $b2) &&
		($c2 eq 'x' || $c1 == $c2) &&
		($d2 eq 'x' || $d1 == $d2)
	    );
}

=head2 Instance Methods

=over 4

=item get_resolver ( )

Returns the Net::DNS::Resolver object used for DNS queries.

=item get_timeout ( )

Returns the timeout in seconds for queries.

=item set_timeout ( $secs )

Sets the timeout in seconds for queries.

=item query_is_in_flight ( )

Returns non-zero if "query" has been called, but "get_answers" has not
yet been called.  Returns zero otherwise.

=item query_ip ( $ipaddr, $dnsbls [, $options])

Issues a set of DNS queries.  Note that the I<query_ip()> method returns as
soon as the DNS queries have been issued.  It does I<not> wait for
DNS responses to come in.  Once I<query_ip()> has been called, the
Net::DNSBL::Client object is said to have a query I<in flight>.  I<query_ip()>
may not be called again while a query is in flight.

$ipaddr is the text representation of an IPv4 or IPv6 address.

$dnsbls is a reference to a list of DNSBL entries; each DNSBL entry
is a hash with the following members:

=over 4

=item domain

(required) The domain to query.  For example, I<zen.spamhaus.org>.

=item type

(optional) The type of DNSBL.  Possible values are I<normal>, meaning
that any returned A record indicates a hit, I<match>, meaning that one
of the returned A records must exactly match a given IP address,
I<mask>, meaning that one of the returned A records must evaluate to
non-zero when bitwise-ANDed against a given IP address, or I<txt>
meaning that TXT records should be looked up and returned (rather than
A records)a.  If omitted, type defaults to I<normal>

=item data

(optional)  For the I<match> and I<mask> types, this data specifies the
required match or the bitwise-AND mask.  In the case of a I<mask> type,
the data can be something like "0.0.0.4", or an integer like "8".  In the
latter case, the integer I<n> must range from 1 to 255 and is equivalent
to 0.0.0.I<n>.

For I<match>-type lookups, one or more of the octets can be specified
as "x" or "X".  For example, specifying a match against
127.0.X.3 will match a return code whose first octet is 127, second is zero,
third is anything, and fourth is 3.

=item userdata

(optional) This element can be any scalar or reference that you like.
It is simply returned back unchanged in the list of hits.

=back

$options, if supplied, is a hash of options.  Currently, three options
are defined:

=over 4

=item early_exit

If set to 1, querying will stop after the first positive result is
received, even if other DNSBLs are being queried.  Default is 0.

=item return_all

If set to 1, then the return value from I<get_answers()> will contain
all DNSBLs that were supplied to I<query_ip()>, even if the DNSBL did not
hit.  If set to 0 (the default), then the return value from
I<get_answers()> only returns entries for those DNSBLs that actually
hit.

=item lookup_keys

This is a hashref of domain_name => key.  Some domains require a secret
key to be inserted just before the domain name; rather than including
the key in the domain, you can separate it out with the lookup_keys hash,
making the returned results more readable.

=back

=item query_domain ( $domain, $dnsbls [, $options])

Similar to query_ip, but considers $domain to be a domain name rather
than an IP address, and does not reverse the domain.

=item get_answers ( )

This method may only be called while a query is in flight.  It waits
for DNS replies to come back and returns a reference to a list of I<hits>.
Once I<get_answers()> returns, a query is no longer in flight.

Note that the list of hits is I<not necessarily> returned in the same
order as the original list of DNSBLs supplied to I<query_ip()>.

Each hit in the returned list is a hash reference containing the
following elements:

=over 4

=item domain

The domain of the DNSBL.

=item hit

Set to 1 if the DNSBL was hit or 0 if it was not.  (You will only get
entries with hit set to 0 if you used the I<return_all> option to I<query_ip()>.)

=item type

The type of the DNSBL (normal, match or mask).

=item data

The data supplied (for normal and mask types)

=item userdata

The userdata as supplied in the I<query_ip()> call

=item actual_hits

Reference to array containing actual A or TXT records returned by the
lookup that caused a hit.

=item replycode

The reply code from the DNS server (as a string).  Likely to be
one of NOERROR, NXDOMAIN, SERVFAIL or TIMEOUT.  (TIMEOUT is not
a real DNS reply code; it is synthesized by this Perl module if
the lookup times out.)

=back

The hit may contain other elements not documented here; you should count
on only the elements documented above.

If no DNSBLs were hit, then a reference to a zero-element list is returned.

=back

=cut

sub get_resolver
{
	my ($self) = @_;
	return $self->{resolver};
}

sub get_timeout
{
	my ($self) = @_;
	return $self->{timeout};
}

sub set_timeout
{
	my ($self, $secs) = @_;
	if (($secs !~ /^\d+$/) || $secs <= 0) {
		croak("Timeout must be a positive integer");
	}
	$self->{timeout} = $secs;
	return $secs;
}

sub query_is_in_flight
{
	my ($self) = @_;
	return $self->{in_flight};
}

sub query_ip
{
	my ($self, $ipaddr, $dnsbls, $options) = @_;
	croak('Cannot issue new query while one is in flight') if $self->{in_flight};
	croak('First argument (ip address) is required')       unless $ipaddr;
	croak('Second argument (dnsbl list) is required')      unless $dnsbls;

	# Reverse the IP address in preparation for lookups
	my $revip = $self->_reverse_address($ipaddr);

	return $self->query_domain($revip, $dnsbls, $options);
}

sub query_domain
{
	my ($self, $ip_or_domain, $dnsbls, $options) = @_;

	croak('Cannot issue new query while one is in flight') if $self->{in_flight};
	croak('First argument (domain) is required')           unless $ip_or_domain;
	croak('Second argument (dnsbl list) is required')      unless $dnsbls;

	foreach my $opt (qw(early_exit return_all)) {
		if ($options && exists($options->{$opt})) {
			$self->{$opt} = $options->{$opt};
		} else {
			$self->{$opt} = 0;
		}
	}

	# Build a hash of domains to query.  The key is the domain;
	# value is an arrayref of type/data pairs
	$self->{domains} = $self->_build_domains($dnsbls);
	my $lookup_keys = {};
	if ($options && exists($options->{lookup_keys}) && ref($options->{lookup_keys}) eq 'HASH') {
		$lookup_keys = $options->{lookup_keys};
	}

	$self->_send_queries($ip_or_domain, $lookup_keys);
}

sub get_answers
{
	my ($self) = @_;
	croak("Cannot call get_answers unless a query is in flight")
	    unless $self->{in_flight};

	$self->_collect_results();

	my $ans = [];
	foreach my $d (keys %{$self->{domains}}) {
		foreach my $r (@{$self->{domains}->{$d}}) {
			push(@$ans, $r) if ( $r->{hit} || $self->{return_all} );
		}
	}

	$self->{in_flight} = 0;
	delete $self->{sel};
	delete $self->{sock_to_domain};
	delete $self->{domains};

	return $ans;
}

sub _build_domains
{
	my($self, $dnsbls) = @_;
	my $domains = {};

	foreach my $entry (@$dnsbls) {
		push(@{$domains->{$entry->{domain}}}, {
			domain    => $entry->{domain},
			type      => ($entry->{type} || 'normal'),
			data      => $entry->{data},
			userdata  => $entry->{userdata},
			hit       => 0,
			replycode => 'TIMEOUT',
		});
	}
	return $domains;
}

sub _send_queries
{
	my ($self, $ip_or_domain, $lookup_keys) = @_;

	$self->{in_flight} = 1;
	$self->{sel} = IO::Select->new();
	$self->{sock_to_domain} = {};

	foreach my $domain (keys(%{$self->{domains}})) {
		my $lookup_key;
		if (exists($lookup_keys->{$domain}) && ($lookup_keys->{$domain} ne '')) {
			$lookup_key = '.' . $lookup_keys->{$domain};
		} else {
			$lookup_key = '';
		}
		my($sock1, $sock2);
		foreach my $e (@{$self->{domains}->{$domain}}) {
			if ($e->{type} eq 'txt') {
				$sock1 ||= $self->{resolver}->bgsend("$ip_or_domain$lookup_key.$domain", 'TXT');
				unless ($sock1) {
					die $self->{resolver}->errorstring;
				}
			} else {
				$sock2 ||= $self->{resolver}->bgsend("$ip_or_domain$lookup_key.$domain", 'A');
				unless ($sock2) {
					die $self->{resolver}->errorstring;
				}
			}
			last if ($sock1 && $sock2);
		}


		if ($sock1) {
			$self->{sock_to_domain}->{$sock1} = $domain;
			$self->{sel}->add($sock1);
		}
		if ($sock2) {
			$self->{sock_to_domain}->{$sock2} = $domain;
			$self->{sel}->add($sock2);
		}
	}
}

sub _collect_results
{
	my ($self) = @_;

	my $terminate = time() + $self->{timeout};
	my $sel = $self->{sel};

	my $got_a_hit = 0;

	while(time() <= $terminate) {
		my $expire = $terminate - time();
		$expire = 1 if ($expire < 1);
		my @ready = $sel->can_read($expire);

		return $got_a_hit unless scalar(@ready);

		foreach my $sock (@ready) {
			my $pack = $self->{resolver}->bgread($sock);
			my $domain = $self->{sock_to_domain}{$sock};
			$sel->remove($sock);
			undef($sock);
			next unless $pack;
			if ($self->_process_reply($domain, $pack)) {
				$got_a_hit = 1;
			}
		}
		return if $got_a_hit && $self->{early_exit};
	}
}

sub _process_reply
{
	my ($self, $domain, $pack, $ans) = @_;

	my $entry = $self->{domains}->{$domain};

	my $rcode = $pack->header->rcode;
	if ($rcode eq 'SERVFAIL' || $rcode eq 'NXDOMAIN') {
		foreach my $dnsbl (@$entry) {
			next if $dnsbl->{hit};
			$dnsbl->{replycode} = $rcode;
		}
		return 0;
	}

	my $got_a_hit = 0;
	foreach my $rr ($pack->answer) {
		next unless ($rr->type eq 'A' || uc($rr->type) eq 'TXT');
		foreach my $dnsbl (@$entry) {
			my $this_rr_hit = 0;
			next if $dnsbl->{hit} && ($dnsbl->{type} eq 'match');
			$dnsbl->{replycode} = $rcode;
			if ($dnsbl->{type} eq 'normal') {
				next unless $rr->type eq 'A';
				$this_rr_hit = 1;
			} elsif ($dnsbl->{type} eq 'match') {
				next unless $rr->type eq 'A';
				next unless $self->_matches($rr->address, $dnsbl->{data});
				$this_rr_hit = 1;
			} elsif ($dnsbl->{type} eq 'mask') {
				next unless $rr->type eq 'A';
				my @quads;
				# For mask, we can be given an IP mask like
				# a.b.c.d, or an integer n.  The latter case
				# is treated as 0.0.0.n.
				if ($dnsbl->{data} =~ /^\d+$/) {
					@quads = (0,0,0,$dnsbl->{data});
				} else {
					@quads = split(/\./,$dnsbl->{data});
				}

				my $mask = unpack('N',pack('C4', @quads));
				my $got  = unpack('N',pack('C4', split(/\./,$rr->address)));
				next unless ($got & $mask);

				$this_rr_hit = 1;
			} elsif ($dnsbl->{type} eq 'txt') {
				next unless uc($rr->type) eq 'TXT';
				$this_rr_hit = 1;
			}

			if( $this_rr_hit ) {
				$dnsbl->{hit} = 1;
				if( ! $dnsbl->{actual_hits} ) {
					$dnsbl->{actual_hits} = [];
				}
				if ($rr->type eq 'A') {
					push @{$dnsbl->{actual_hits}}, $rr->address;
				} else {
					push @{$dnsbl->{actual_hits}}, $rr->txtdata;
				}
				$got_a_hit = 1;
			}
		}
	}
	return $got_a_hit;
}

sub _reverse_address
{
	my ($self, $addr) = @_;

	# The following regex handles both regular IPv4 addresses
	# and IPv6-mapped IPV4 addresses (::ffff:a.b.c.d)
	if ($addr =~ /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {
		return "$4.$3.$2.$1";
	}
	if ($addr =~ /:/) {
		$addr = $self->_expand_ipv6_address($addr);
		$addr =~ s/://g;
		return join('.', reverse(split(//, $addr)));
	}

	croak("Unrecognized IP address '$addr'");
}

sub _expand_ipv6_address
{
	my ($self, $addr) = @_;

	return '0000:0000:0000:0000:0000:0000:0000:0000' if ($addr eq '::');
	if ($addr =~ /::/) {
		# Do nothing if more than one pair of colons
		return $addr if ($addr =~ /::.*::/);

		# Make sure we don't begin or end with ::
		$addr = "0000$addr" if $addr =~ /^::/;
		$addr .= '0000' if $addr =~ /::$/;

		# Count number of colons
		my $colons = ($addr =~ tr/:/:/);
		if ($colons < 8) {
			my $missing = ':' . ('0000:' x (8 - $colons));
			$addr =~ s/::/$missing/;
		}
	}

	# Pad short fields
	return join(':', map { (length($_) < 4 ? ('0' x (4-length($_)) . $_) : $_) } (split(/:/, $addr)));
}

1;

__END__

=head1 DEPENDENCIES

L<Net::DNS::Resolver>, L<IO::Select>

=head1 AUTHOR

Dianne Skoll <dianne@skoll.ca>
Dave O'Neill <dmo@dmo.ca>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Roaring Penguin Software
Copyright (c) 2022 Dianne Skoll

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
