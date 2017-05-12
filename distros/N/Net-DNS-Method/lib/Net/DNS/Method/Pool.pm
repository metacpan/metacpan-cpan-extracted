package Net::DNS::Method::Pool;

require 5.005_62;

use Carp;
use Net::DNS;
use NetAddr::IP 3.00;
use Net::DNS::Method;
use vars qw($VERSION @ISA);

@ISA = qw(Net::DNS::Method);

use strict;
use warnings;

$VERSION = '2.00';

				# Default responses
our $DEF_ZONE	= 'some.com';
our $DEF_PREFIX	= 'dyn-';
our $DEF_TTL	= '36000';	# 10 hours

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Net::DNS::Method::Pool";

    my $ref = shift;

    my $self = 
    {
	start => time,
	counter => {},
	zone => (defined($ref) && defined($ref->{BaseDomain}) ? 
		 $ref->{BaseDomain} : $DEF_ZONE), 
	    prefix => (defined($ref) && defined($ref->{Prefix}) ? 
		       $ref->{Prefix} : $DEF_PREFIX),
		ttl => (defined($ref) && defined($ref->{ttl}) ? 
			$ref->{ttl} : $DEF_TTL),
		    pool => []
    };

    if (exists $ref->{Pool}) {
	for my $ip (@{$ref->{Pool}}) {
	    my $a = new NetAddr::IP $ip;

	    croak "Address $ip cannot be parsed"
		unless $a;
	    
	    push @{$self->{pool}}, $a;
	}
    }
    else {
	croak 
	    "Net::DNS::Method::Pool requires a pool of IP addresses to serve";
    }
    
    bless $self, $class;
}

sub _parse_ptr ($$) {
    my $self	= shift;
    my $q	= shift;

    if ($q->qname =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)\.in-addr\.arpa\.?$/i) {
#	warn "_parse_ptr found $4.$3.$2.$1\n";
	return new NetAddr::IP "$4.$3.$2.$1";
    }

    return undef;
}

sub _parse_a ($$) {
    my $self	= shift;
    my $q	= shift;

    my $name = $q->qname;

#    warn "check on $name\n";

    if (index($name, $self->{prefix}) == 0) {
	substr($name, 0, length($self->{prefix})) = '';
    }
    else { return undef; }

#    warn "match 1 on $name\n";

    if (my $i = index($name, '.' . $self->{zone})) {
	substr($name, $i, length($self->{zone}) + 1) = '';
    }
    else { return undef; }

#    warn "match 2 on $name\n";

    if ($name =~ m/^([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+)$/i
	and $1 >= 0 and $1 <= 255
	and $2 >= 0 and $2 <= 255
	and $3 >= 0 and $3 <= 255
	and $4 >= 0 and $4 <= 255) 
    {
#	warn "_parse_a found $1.$2.$3.$4\n";
	return new NetAddr::IP "$1.$2.$3.$4";
    }

    return undef;
}

sub PTR {
    my $self = shift;
    my $q = shift;
    my $ans = shift;

    if (my $a = $self->_parse_ptr($q)) {
	for my $s (@{$self->{pool}}) {
	    if ($s->contains($a)) {
		my $name = $a->addr;
		$name =~ s/\./-/g;
		substr($name, 0, 0) = $self->{prefix};
		$name .= '.';
		$name .= $self->{zone};

		$ans->push('answer', new Net::DNS::RR $q->qname . 
			   ' ' . $self->{ttl} . " IN PTR " . 
			   $name);
		$ans->header->rcode('NOERROR');
		return NS_OK | NS_STOP;
	    }
	}
    }

    return NS_FAIL;		# No match or error
}

sub A {
    my $self = shift;
    my $q = shift;
    my $ans = shift;

    if (my $a = $self->_parse_a($q)) {
	for my $s (@{$self->{pool}}) {
	    if ($s->contains($a)) {
		$ans->push('answer', new Net::DNS::RR $q->qname . 
			   ' ' . $self->{ttl} . " IN A " . 
			   $a->addr);
		$ans->header->rcode('NOERROR');
		return NS_OK | NS_STOP;
	    }
	}
    }

    return NS_FAIL;		# No match or error
}

sub ANY { return A(@_ )|| PTR(@_); }

1;
__END__

=head1 NAME

Net::DNS::Method::Pool - A DNS resolver that handles the names for address pools

=head1 SYNOPSIS

  use Net::DNS::Method::Pool;

  my $Pool = new Net::DNS::Method::Pool { 
      Prefix => 'dhcp-',
      BaseDomain => 'pool.x.com',
      Pool => [ "10.0.0.0/16", "10.1.0.0/16" ],
      ttl => 3600
      };


=head1 DESCRIPTION

This class adds support for naming ranges of IP addresses using
rules. It supports answers to A and PTR queries, so that proper
forward and reverse references can be implemented.

The example above, will answer a PTR query for any address in the
10.0.0.0/15 range. A query for the PTR of 10.0.0.1 will return

    1.0.0.10.in-addr.arpa. IN PTR dhcp-10-0-0-1.pool.x.com

While a query for dhcp-10-1-1-1.pool.x.com will return

    dhcp-10-1-1-1.pool.x.com. IN A 10.1.1.1

The TTL for the answer is controlled by the value of ttl in
the hash reference passed to C<-E<gt>new()>.

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 1.00

Original version; created by h2xs 1.20 with options

  -ACOXfn
	Net::DNS::Method::Pool
	-v
	1.00

=item 1.10

Updated to use NetAddr::IP v3.00.

=item 2.00

Packaged for public release.

=back

=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1), Net::DNS::Method(3).

=cut
