package Net::Subnet;

use strict;
use Socket;
BEGIN {
    if (defined &Socket::inet_pton) {
        Socket->import(qw(inet_pton AF_INET6));
    } else {
        require Socket6;
        Socket6->import(qw(inet_pton AF_INET6));
    }
};


use base 'Exporter';
our @EXPORT = qw(subnet_matcher subnet_classifier sort_subnets);

our $VERSION = '1.03';

sub cidr2mask_v4 {
    my ($length) = @_;
    return pack "N", 0xffffffff << (32 - $length);
}

sub cidr2mask_v6 {
    my ($length) = @_;
    return pack('B128', '1' x $length);
}

sub subnet_matcher {
    @_ > 1 and goto &multi_matcher;

    my ($net, $mask) = split m[/], shift;
    return $net =~ /:/
        ? ipv6_matcher($net, $mask)
        : ipv4_matcher($net, $mask);
}

sub ipv4_matcher {
    my ($net, $mask) = @_;

    $net = inet_aton($net);
    $mask = $mask =~ /\./ ? inet_aton($mask) : cidr2mask_v4($mask);

    my $masked_net = $net & $mask;

    return sub { ((inet_aton(shift) // return !1) & $mask) eq $masked_net };
}

sub ipv6_matcher {
    my ($net, $mask) = @_;

    $net = inet_pton(AF_INET6, $net);
    $mask = $mask =~ /:/ ? inet_pton(AF_INET6, $mask) : cidr2mask_v6($mask);

    my $masked_net = $net & $mask;

    return sub { ((inet_pton(AF_INET6,shift)//return!1) & $mask) eq $masked_net}
}

sub multi_matcher {
    my @v4 = map subnet_matcher($_), grep !/:/, @_;
    my @v6 = map subnet_matcher($_), grep  /:/, @_;

    return sub {
        $_->($_[0]) and return 1 for $_[0] =~ /:/ ? @v6 : @v4;
        return !!0;
    }
}

use constant MATCHER => 0;
use constant SUBNET  => 1;

sub subnet_classifier {
    #                    MATCHER,     SUBNET
    my @v4 = map [ subnet_matcher($_), $_ ], grep !/:/, @_;
    my @v6 = map [ subnet_matcher($_), $_ ], grep  /:/, @_;

    return sub {
        $_->[MATCHER]->($_[0]) and return $_->[SUBNET]
            for $_[0] =~ /:/ ? @v6 : @v4;
        return undef;
    }
}

sub sort_subnets {
    my @unsorted;
    for (@_) {
        my ($net, $mask) = split m[/];

        $mask = $net =~ /:/
            ? ($mask =~ /:/ ? inet_pton(AF_INET6, $mask) : cidr2mask_v6($mask))
            : ($mask =~ /\./ ? inet_aton($mask) : cidr2mask_v4($mask));

        $net = $net =~ /:/
            ? inet_pton(AF_INET6, $net)
            : inet_aton($net);

        push @unsorted, sprintf "%-16s%-16s%s", ($net & $mask), $mask, $_;
    }

    return map substr($_, 32), reverse sort @unsorted;
}

1;

__END__

=head1 NAME

Net::Subnet - Fast IP-in-subnet matcher for IPv4 and IPv6, CIDR or mask.

=head1 SYNOPSIS

    use Net::Subnet;

    # CIDR notation
    my $is_rfc1918 = subnet_matcher qw(
        10.0.0.0/8
        172.16.0.0/12
        192.168.0.0/16
    );

    # Subnet mask notation
    my $is_rfc1918 = subnet_matcher qw(
        10.0.0.0/255.0.0.0
        172.16.0.0/255.240.0.0
        192.168.0.0/255.255.0.0
    );

    print $is_rfc1918->('192.168.1.1') ? 'yes' : 'no';  # prints "yes"
    print $is_rfc1918->('8.8.8.8')     ? 'yes' : 'no';  # prints "no"

    # Mixed IPv4 and IPv6
    my $in_office_network = subnet_matcher qw(
        192.168.1.0/24
        2001:db8:1337::/48
    );

    $x = $in_office_network->('192.168.1.1');            # $x is true
    $x = $in_office_network->('2001:db8:dead:beef::5');  # $x is false

    my $classifier = subnet_classifier qw(
        192.168.1.0/24
        2001:db8:1337::/48
        10.0.0.0/255.0.0.0
    );

    $x = $classifier->('192.168.1.250');        # $x is '192.168.1.0/24'
    $x = $classifier->('2001:db8:1337::babe');  # $x is '2001:db8:1337::/48'
    $x = $classifier->('10.2.127.1');           # $x is '10.0.0.0/255.0.0.0'
    $x = $classifier->('8.8.8.8');              # $x is undef

    # More specific subnets (smaller subnets) must be listed first
    my @subnets = sort_subnets(
        '192.168.0.0/24',  # second
        '192.168.0.1/32',  # first
        '192.168.0.0/16',  # third
    );
    my $classifier = subnet_classifier @subnets;

=head1 DESCRIPTION

This is a simple but fast pure Perl module for determining whether a given IP
address is in a given set of IP subnets. It's iterative, and it doesn't use any
fancy tries, but because it uses simple bitwise operations on strings it's
still very fast.

All documented functions are exported by default.

Subnets have to be given in "address/mask" or "address/length" (CIDR) format.
The Socket and Socket6 modules are used to normalise addresses, which means
that any of the address formats supported by inet_aton and inet_pton can be
used with Net::Subnet.

=head1 FUNCTIONS

=head2 subnet_matcher(@subnets)

Returns a reference to a function that returns true if the given IP address is
in @subnets, false it it's not.

=head2 subnet_classifier(@subnets)

Returns a reference to a function that returns the element from @subnets that
matches the given IP address, or undef if none matched.

=head2 sort_subnets(@subnets)

Returns @subnets in reverse order of prefix length and prefix; use this with
subnet_matcher or subnet_classifier if your subnet list has overlapping ranges
and it's not already sorted most-specific-first.

=head1 TRICKS

=head2 Generating PTR records for IPv6

If you need to classify an IP address, but want some other value than the
original subnet string, just use a hash. You could even use code references;
here's an example of how to generate dynamic reverse DNS records for IPv6
addresses:

    my %ptr = (
        '2001:db8:1337:d00d::/64' => sub {
            my $hostname = get_machine_name(shift);
            return $hostname =~ /\.$/ ? $hostname : "$hostname.example.org.";
        },
        '2001:db8:1337:babe::/64' => sub {
            my $hostname = get_machine_name(shift);
            return $hostname =~ /\.$/ ? $hostname : "$hostname.example.net.";
        },
        '::/0' => sub {
            (my $ip = shift) =~ s/:/x/g;
            return "$ip.unknown.example.com.";
        },
    );
    my $classifier = subnet_classifier sort_subnets keys %ptr;

    while (my $ip = readline) {
        # We get IP adresses from STDIN and return the hostnames on STDOUT

        print $ptr{ $classifier->($ip) }->($ip), "\n";
    }

=head2 Matching ::ffff:192.168.1.200

IPv4 subnets only match IPv4 addresses. If you need to match IPv4-mapped IPv6
addresses, i.e. IPv4 addresses with C<::ffff:> stuck in front of them, simply
remove that part before matching:

    my $matcher = subnet_matcher qw(192.168.1.0/22);
    $ip =~ s/^::ffff://;
    my $boolean = $matcher->($ip);

Alternatively, translate the subnet definition to IPv6 notation: C<1.2.3.0/24>
becomes C<::ffff:1.2.3.0/120>. If you do this, hexadecimal addresses such as
C<::ffff:102:304> will also match, but IPv4 addresses without C<::ffff:> will
no longer match unless you include C<1.2.3.0/24> as well.

    my $matcher = subnet_matcher qw(::ffff:192.168.1.0/118 192.168.1.0/22);
    my $boolean = $matcher->($ip);

=head1 CAVEATS

No argument verification is done; garbage in, garbage out. If you give it
hostnames, DNS may be used to resolve them, courtesy of the Socket and Socket6
modules.

=head1 AUTHOR

Juerd Waalboer <juerd#@tnx.nl>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
