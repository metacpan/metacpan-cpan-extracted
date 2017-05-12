# NAME

Net::Works - Sane APIs for IP addresses and networks

# VERSION

version 0.22

# DESCRIPTION

The [NetAddr::IP](https://metacpan.org/pod/NetAddr::IP) module is very complete, correct, and useful. However, its
API design is a bit crufty. This distro provides an alternative API that aims
to address the biggest problems with that module's API, as well as adding some
additional features.

This distro contains two modules, [Net::Works::Address](https://metacpan.org/pod/Net::Works::Address) and
[Net::Works::Network](https://metacpan.org/pod/Net::Works::Network).

**NOTE: This distro's APIs are still in flux. Use at your own risk.**

# Net::Works VERSUS NetAddr::IP

Here are some of the key differences between the two distributions:

- Separation of address from network

    `Net::Works` provides two classes, one for single IP addresses and one for
    networks (and subnets). With [NetAddr::IP](https://metacpan.org/pod/NetAddr::IP) a single address is represented as
    a /32 or /128 subnet. This is technically correct but can make the API harder
    to use. Whenever you want a single IP you're always stuck checking that the
    object you're working with is the size of a single address subnet.

- Multiple constructors

    [Net::Works](https://metacpan.org/pod/Net::Works) allows you to construct an IP address from a string ("192.0.2.1")
    or an integer (3221225985) using separate constructors.

- Next & previous IP

    You can get the next and previous address from [Net::Works::Address](https://metacpan.org/pod/Net::Works::Address) object,
    regardless of whether or not that address is in the same subnet.

- Constructors throw exceptions

    If you pass bad data to a constructor you'll get an exception.

- Sane iterator and first/last

    The iterator provided by [Net::Works::Network](https://metacpan.org/pod/Net::Works::Network) has no confusing special
    cases. It always returns all the addresses in a network, including the network
    and broadcast addresses. Similarly, the `$network->first()` and `$network->last()` do not return different results for different sized networks.

- Split a range into subnets

    The [Net::Works::Network](https://metacpan.org/pod/Net::Works::Network) class provides a `Net::Works::Network->range_as_subnets` method that takes a start and end IP
    address and splits this into a set of subnets that include all addresses in
    the range.

- Does less

    This distro does not support every method provided by [NetAddr::IP](https://metacpan.org/pod/NetAddr::IP). Patches
    to add more features are welcome, however.

# BUGS

Please report any bugs or feature requests to `bug-net-works@rt.cpan.org`, or
through the web interface at [http://rt.cpan.org](http://rt.cpan.org).  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

# AUTHORS

- Dave Rolsky <autarch@urth.org>
- Greg Oschwald <oschwald@cpan.org>
- Olaf Alders <oalders@wundercounter.com>

# CONTRIBUTORS

- Alexander Hartmaier <abraxxa@cpan.org>
- Dave Rolsky <drolsky@maxmind.com>
- Greg Oschwald <goschwald@maxmind.com>
- TJ Mather <tjmather@maxmind.com>
- William Stevenson <wstevenson@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
