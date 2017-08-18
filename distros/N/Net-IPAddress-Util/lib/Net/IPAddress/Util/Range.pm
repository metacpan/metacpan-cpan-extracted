package Net::IPAddress::Util::Range;

use strict;
use warnings;
use 5.010;

use overload (
    '""' => 'as_string',
    '<=>' => '_spaceship',
    'cmp' => '_spaceship',
);

use Exporter qw( import );
use Net::IPAddress::Util qw( :constr :manip );
require Net::IPAddress::Util::Collection;

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my ($arg_ref) = @_;
    my ($l, $u);
    if ($arg_ref->{ lower } && $arg_ref->{ upper }) {
        $arg_ref->{ lower } = IP($arg_ref->{ lower }) unless ref($arg_ref->{ lower });
        $arg_ref->{ upper } = IP($arg_ref->{ upper }) unless ref($arg_ref->{ upper });
        if ($arg_ref->{ lower } > $arg_ref->{ upper }) {
            ($arg_ref->{ lower }, $arg_ref->{ upper }) = ($arg_ref->{ upper }, $arg_ref->{ lower });
        }
        return bless $arg_ref => $class;
    }
    elsif ($arg_ref->{ ip }) {
        my $ip;
        my $nm = 2;
        if ($arg_ref->{ netmask }) {
            $ip = IP($arg_ref->{ ip      });
            my $was_ipv4 = $ip->is_ipv4;
            $nm = IP($arg_ref->{ netmask });
            $ip &= $nm;
            $nm = ~$nm;
            if ($was_ipv4) {
                $nm &= ipv4_mask();
            }
            $l = $ip;
            $u = $ip | $nm;
        }
        elsif ($arg_ref->{ ip } =~ m{(.*?)/(\d+)}) {
            my ($t, $cidr) = ($1, $2);
            $ip = IP($t);
            my $was_ipv4 = $ip->is_ipv4;
            $nm = implode_ip(substr(('1' x 128) . ('0' x (($was_ipv4 ? 32 : 128) - $cidr)), -128));
            $ip &= $nm;
            if ($was_ipv4) {
                my $fixup = ipv4_flag();
                $ip |= $fixup;
            }
            $l = $ip;
            $u = $ip | ~$nm;
        }
        elsif ($arg_ref->{ cidr }) {
            $ip = IP($arg_ref->{ ip });
            my $was_ipv4 = $ip->is_ipv4;
            my $cidr = $arg_ref->{ cidr };
            $nm = implode_ip(substr(('1' x 128) . ('0' x (($was_ipv4 ? 32 : 128) - $cidr)), -128));
            $ip &= $nm;
            if ($was_ipv4) {
                my $fixup = ipv4_flag();
                $ip |= $fixup;
            }
            $l = $ip;
            $u = $ip | ~$nm;
        }
        else {
            $l = IP($arg_ref->{ ip });
            $u = IP($arg_ref->{ ip });
        }
    }
    return bless { lower => $l, upper => $u } => $class;
}

sub as_string {
    my $self = shift;
    return "($self->{ lower } .. $self->{ upper })";
}

sub outer_bounds {
    my $self = shift;
    my @l = explode_ip($self->{ lower });
    my @u = explode_ip($self->{ upper });
    my @cidr = common_prefix(@l, @u);
    my $cidr = scalar @cidr;
    my $base = implode_ip(ip_pad_prefix(@cidr));
    if ($base->is_ipv4()) {
        $cidr -= 96;
    }
    my @mask = prefix_mask(@l, @u);
    my $nm = implode_ip(ip_pad_prefix(@mask));
    my $x = ~$nm;
    my $hi = IP($base);
    $hi |= $x;
    if ($base->is_ipv4()) {
        $nm &= ipv4_mask();
    }
    return {
        base    => $base,
        cidr    => $cidr,
        netmask => $nm,
        highest => $hi,
    };
}

sub inner_bounds {
    my $self = shift;
    return $self if $self->{ upper } == $self->{ lower };
    my $bounds = $self->outer_bounds();
    my $new = ref($self)->new($self);
    while ($bounds->{ highest } > $self->{ upper } or $bounds->{ base } < $self->{ lower }) {
        $new = ref($self)->new({ ip => $self->{ lower }, cidr => $bounds->{ cidr } + 1 });
        $bounds = $new->outer_bounds();
    }
    return $new;
}

sub as_cidr {
    my $self = shift;
    my $hr = $self->outer_bounds();
    return "$hr->{ base }" . '/' . "$hr->{ cidr }";
}

sub as_netmask {
    my $self = shift;
    my $hr = $self->outer_bounds();
    return "$hr->{ base }" . ' (' . "$hr->{ netmask }" . ')';
}

sub loose {
    my $self = shift;
    my $hr = $self->outer_bounds();
    return ref($self)->new({ lower => $hr->{ base }, upper => $hr->{ highest } });
}

sub _spaceship {
    my ($self, $rhs, $swapped) = @_;
    ($self, $rhs) = ($rhs, $self) if $swapped;
    $rhs = ref($self)->new({ ip => $rhs }) unless ref($self) eq ref($rhs);
    return
        $self->{ lower } <=> $rhs->{ lower }
        || $self->{ upper } <=> $rhs->{ upper }
        ;
}

sub tight {
    my $self = shift;
    my $inner = $self->inner_bounds();
    my $rv = Net::IPAddress::Util::Collection->new();
    push @$rv, $inner;
    if ($inner->{ upper } < $self->{ upper }) {
        my $remainder = ref($self)->new({ lower => $inner->{ upper } + 1, upper => $self->{ upper } });
        push @$rv, @{$remainder->tight()};
    }
    return $rv;
}

sub lower {
    my $self = shift;
    return $self->{ lower };
}

sub upper {
    my $self = shift;
    return $self->{ upper };
}

1;

__END__

=head1 NAME

Net::IPAddress::Util::Range - Representation of a range of IP addresses

=head1 VERSION

Version 3.029

=head1 SYNOPSIS

    use Net::IPAddress::Util::Range;

    my $x = '192.168.0.3';
    my $y = '192.168.0.123';

    my $range = Net::IPAddress::Util::Range->new({ lower => $x, upper => $y });

    print "$range\n"; # (192.168.0.3 .. 192.168.0.123)

    for (@{$range->tight()}) {
        print "$_\n";
    }

    my $w = '192.168.0.0/24';

    my $range = Net::IPAddress::Util::Range->new({ ip => $w });

    my $v = '192.168.0.0';

    my $range = Net::IPAddress::Util::Range->new({ ip => $v, cidr => 24 });

    my $z = '255.255.255.0';

    my $range = Net::IPAddress::Util::Range->new({ ip => $v, netmask => $z });

=head1 DESCRIPTION

Sometimes when dealing with IP Addresses, it can be nice to talk about 
contiguous ranges of them as whole collections of addresses without worrying 
that the contiguous range is exactly a CIDR-compatible range.

This is what Net::IPAdress::Util::Range is for. Objects of this class act
as type-checked pairs of lower and upper bounds of a range of IP Addresses.

=head1 CLASS METHODS

=head2 new

The constructor. Takes a hashref with:

=over

=item C<lower> and C<upper>

In this case, construction is straightforward. The two values must be either
L<Net::IPAddress::Util> objects, or something that can be used to construct one.

=item C<ip>

If the C<ip> is a L<Net::IPAddress::Util> object (or something that can be used
to construct one), then you get a Range consisting of a single IP. This may
seem redundant, but allows L<Net::IPAddress::Util::Collection> to do magic.

=over

Also, as a convenience, CIDR strings (of the form "N.N.N.N/X", etc) may be
passed in, and you'll get back a Range representing that whole CIDR.

=back

=item C<ip> and C<cidr>

Pass in an IP and a numeric CIDR (which B<MUST> be valid for the version (4 or 
6) of the IP), and you'll get back a Range representing that whole CIDR.

=item C<ip> and C<netmask>

Pass in two IPs, of the same version, and they'll be treated exacatly as the 
argument names suggest. The C<netmask> argument B<MUST> (in binary) start with
zero or more ones, followed by enough zeroes to pad out to the correct number
of bits (either 32 or 128 for IPv4 or IPv6 respectively). The C<ip> argument 
B<MUST> have the same number of right-hand zeroes as the C<netmask> argument.

=back

=head1 OBJECT METHODS

=head2 '""'

=head2 as_string

Objects stringify to a representation of their range.

=head2 as_cidr

Stringification for CIDR-style strings.

=head2 as_netmask

Stringification for Netmask-style strings.

=head2 outer_bounds

Return the bounds of the smallest subnet capable of completely containing
the addresses in this range. Note that this is not automatically the same
thing as "the subnet that matches this range", as a range may or may not be
aligned to legal subnet boundaries.

=head2 inner_bounds

Return the bounds of the largest subnet capable of being completely contained
by the addresses in this range. Note that this is not automatically the same
thing as "the subnet that matches this range", as a range may or may not be
aligned to legal subnet boundaries.

=head2 tight

Returns a collection of subnets that (between them) exactly match the
addresses in this range. The returned object is a Net::IPAddress::Util::Collection,
which can be treated as an array reference of Net::IPAddress::Util::Range objects.

=head2 loose

Returns a blessed object (of this class) representing the range returned by outer_bounds().

=head2 lower

=head2 upper

Get the lower or upper bounds of this range.

=cut

