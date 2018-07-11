# NAME

Net::IP::Checker - IPv4/IPv6 addresses validator

# VERSION

version 0.02

# SYNOPSIS

    use Net::IP::Checker qw[:ALL];
    
    my $ip = '172.16.0.216';
    ip_is_ipv4( $ip ) and print "$ip is IPv4";

    $ip = 'dead:beef:89ab:cdef:0123:4567:89ab:cdef';
    ip_is_ipv6( $ip ) and print "$ip is IPv6";

    print ip_get_version( $ip );

# DESCRIPTION

Fork of Net::IP::Minimal that validate IPv4 and IPv6 addresses correctly

# NAME

Net::IP::Checker

# SEE ALSO

[Net::IP](https://metacpan.org/pod/Net::IP), [Net::IP::Checker](https://metacpan.org/pod/Net::IP::Checker), [Net::IP::Lite](https://metacpan.org/pod/Net::IP::Lite)

# FUNCTIONS

The same as [Net::IP](https://metacpan.org/pod/Net::IP) these functions are not exported by default. You may import them explicitly
or use `:PROC` to import them all.

- `ip_get_version`

    Try to guess the IP version of an IP address.

        Params  : IP address
        Returns : 4, 6, undef(unable to determine)

- `ip_is_ipv4`

    Check if an IP address is of type 4.

        Params  : IP address
        Returns : 1 (yes) or 0 (no)

- `ip_is_ipv6`

    Check if an IP address is of type 6.

        Params            : IP address
        Returns           : 1 (yes) or 0 (no)

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
