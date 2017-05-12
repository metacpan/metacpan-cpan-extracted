package Net::Subnet::Count;

use strict;
use vars qw($VERSION @ISA $cache_num);
use Carp;
use IP::Address;

require Exporter;

@ISA = qw();
$VERSION = '1.20';

# Preloaded methods go here.

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Net::Subnet::Count";
    my $self = { 'subnets' => {},
		 'count' => {},
		 'cache' => [],
		 'cache_num' => 5,
		};
    bless $self, $class;
    my %data = @_;
    foreach my $subnet (keys %data) {
	$self->add($subnet, $data{$subnet});
    }
    return $self;
}

sub cache {
    my $self = shift;
    my $ret = $self->{'cache_num'};
    $self->{'cache_num'} = shift if (@_ and $_[0] >= 0);
    $ret;
}

sub add {
    my $self = shift;
    my $subnet = shift;
    if (ref($_[0]) eq 'ARRAY') {
	$self->_add_entry($subnet, @{$_[0]});
    }
    else {
	$self->_add_entry($subnet, @_);
    }
}

sub _add_entry {
    my $self = shift;
    my $name = shift;
    if (not exists $self->{'subnets'}->{$name}) {
	$self->{'subnets'}->{$name} = [];
	$self->{'count'}->{$name} = 0;
    }
    push @{$self->{'subnets'}->{$name}}, @_;
}

sub _add_cache {
    my $self = shift;
    my ($label, $ip) = (shift, shift);
    unshift @{$self->{'cache'}}, [$label, $ip];
    while (@{$self->{'cache'}} > $self->{'cache_num'}) {
	pop @{$self->{'cache'}};
    }
}

sub count {
    my $self = shift;
  IP:
    while (my $ip = shift) {
	foreach my $r_pair (@{$self->{'cache'}}) {
	    my ($subnet, $ip_net) = @{$r_pair};
	    if ($ip_net->contains($ip)) { # Match
		++$self->{'count'}->{$subnet};
		next IP;
	    }
	}
	foreach my $subnet (keys %{$self->{'subnets'}}) {
	    foreach my $ip_net (@{$self->{'subnets'}->{$subnet}}) {
		if ($ip_net->contains($ip)) { # Match
		    $self->_add_cache($subnet, $ip_net);
		    ++$self->{'count'}->{$subnet};
		    next IP;
		}
	    }
	}
    }
}

sub valcount {
    my $self = shift;
  IP:
    while (my $ip = shift) {
	my $value = shift;
	foreach my $r_pair (@{$self->{'cache'}}) {
	    my ($subnet, $ip_net) = @{$r_pair};
	    if ($ip_net->contains($ip)) { # Match
		$self->{'count'}->{$subnet} += $value;
		next IP;
	    }
	}
	foreach my $subnet (keys %{$self->{'subnets'}}) {
	    foreach my $ip_net (@{$self->{'subnets'}->{$subnet}}) {
		if ($ip_net->contains($ip)) { # Match
		    $self->_add_cache($subnet, $ip_net);
		    $self->{'count'}->{$subnet} += $value;
		    next IP;
		}
	    }
	}
    }
}

sub result {
    my $self = shift;
    my %res;
    foreach my $subnet (keys %{$self->{'count'}}) {
	$res{$subnet} = $self->{'count'}->{$subnet};
    }
    return \%res;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Net::Subnet::Count - Count hosts in named subnets

=head1 SYNOPSIS

  use Net::Subnet::Count;
  use IP::Address;

  my $counter = new Net::Subnet::Count;

  $counter->add('subnet-00', new IP::Address("10.0.0.0/24"));
  $counter->add('other', @array_of_ip_addresses);
  $counter->add('other', @another_array_of_ip_addresses);

  $counter->cache(10);

  $counter->count(new IP::Address("10.0.3.17"));
  $counter->count(@array_of_ip_addresses);

  $counter->valcount(new IP::Address("10.0.3.17"), 23);
  @array_of_ipaddr_and_values = (new IP::Address("10.0.3.17"), 23,
				new IP::Address("101.0.23.107"), 2);
  $counter->valcount(@array_of_ipaddr_and_values);

  my $r_count = $counter->result;

  foreach my $subnet (keys %{$r_count}) {
      print "Subnet $subnet had ", $r_count->{$subnet}, " visits.\n";
  }

=head1 DESCRIPTION

This module implements a symplistic way to match individual IP
Addresses to subnets. It can be used to, among other things, help
analyze HTTPD logs.

The following methods are implemented.

=over

=item C<-E<gt>new>

Creates a new counter. This method can be called passing as argument a
hash where the keys are the name of the subnet group and the values
are references to arrays of C<IP::Address> objects referencing each
specific subnet. This is probably ok for static initializations.

=item C<-E<gt>add>

Adds a subnet group. The first parameter is the name of the group
being added. If it's a new name, a new entry will be created. Else the
given subnets are added to the existing ones, like in the example
above.

=item C<-E<gt>count>

Verifies if the C<IP::Address>es are contained in any of the given
subnets. If this is the case, the corresponding totals are updated.

=item C<-E<gt>valcount>

The same as C<-E<gt>count> but the argument is an array consisting
of C<IP::Address>es and value pairs.

=item C<-E<gt>result>

Returns a reference to a hash containing the respective totals for
each subnet group. The key to the hash is the subnet name given with
C<-E<gt>add>, the value is how many C<IP::Address> objects have been
found to match that subnet group.

=item C<-E<gt>cache>

Since in usual applications C<IP::Addresses> from the same subnet will
tend to be grouped in clusters like in the case of HTTPD logs some
caching is attempted to speed things up. The caching consists in
storing the last few entries matched in an LRU list which is checked
before going through all the stored subnets.

This can improve response times if tuned sensibly, however consider
that every miss will cause every entry in the cache to be checked
twice, one in the cache and one in the normal process so it's
important to tune the cache.

The default cache size is 5, which can be changed by calling the
C<-E<gt>cache> method as in the example. The old value of the cache
size is returned.

=back

=head1 AUTHOR

Luis E. Munoz <lem@cantv.net>. Alvaro Carvajal <alvaro@cantv.net>
contributed the valcount method.

=head1 SEE ALSO

perl(1), IP::Address(1).

=cut
