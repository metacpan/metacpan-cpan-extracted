package Net::IPAddress::Filter;

use strict;
use warnings;

# ABSTRACT: A compact and fast IP Address range filter
our $VERSION = '20140113'; # VERSION


use Net::CIDR::Lite;
use Set::IntervalTree;    # XS module.

our $CIDR_REGEX = qr{/ \d+ \z}xms;


sub new {
    my $class = shift;

    my $self = { filter => Set::IntervalTree->new(), };

    return bless $self, $class;
}


sub add_range {
    my ( $self, $start_ip, $end_ip ) = @_;

    my ($start_num, $end_num) = _get_start_and_end_numbers($start_ip, $end_ip);

    # Different versions of Set::IntervalTree use different-closed intervals,
    # so need to allow for that.
    if ( $Set::IntervalTree::VERSION < 0.08 ) {
        $self->{filter}->insert($start_ip . ($end_ip ? ",$end_ip" : ''), $start_num - 1, $end_num + 1 );
    }
    else {
        $self->{filter}->insert($start_ip . ($end_ip ? ",$end_ip" : ''), $start_num, $end_num + 1 );
    }

    return 1;
}


sub add_range_with_value {
    my ( $self, $value, $start_ip, $end_ip ) = @_;

    my ($start_num, $end_num) = _get_start_and_end_numbers($start_ip, $end_ip);

    # Different versions of Set::IntervalTree use different-closed intervals,
    # so need to allow for that.
    if ( $Set::IntervalTree::VERSION < 0.08 ) {
        $self->{filter}->insert( $value, $start_num - 1, $end_num + 1 );
    }
    else {
        $self->{filter}->insert( $value, $start_num, $end_num + 1 );
    }

    return 1;
}


sub in_filter {
    my ( $self, $test_ip ) = @_;

    my $test_num = _ip_address_to_number($test_ip);
    my $end_num  = $Set::IntervalTree::VERSION < 0.08 ? $test_num : $test_num + 1;

    my $found = $self->{filter}->fetch( $test_num, $end_num ) || return 0;

    return scalar @$found;
}


sub get_matches {
    my ( $self, $test_ip ) = @_;

    my $test_num = _ip_address_to_number($test_ip);
    my $end_num  = $Set::IntervalTree::VERSION < 0.08 ? $test_num : $test_num + 1;

    return $self->{filter}->fetch( $test_num, $end_num );

}


sub _get_start_and_end_numbers {
    my ( $start_ip, $end_ip ) = @_;

    my ($start_num, $end_num);

    if ( $start_ip =~ $CIDR_REGEX ) {
        my $cidr = Net::CIDR::Lite->new;
        $cidr->add($start_ip);
        my ( $start_cidr, $end_cidr ) = split /-/, @{ $cidr->list_range() }[0];
        $start_num = _ip_address_to_number($start_cidr);
        $end_num = _ip_address_to_number($end_cidr);
    }
    else {
        $start_num = _ip_address_to_number($start_ip);
        $end_num = $end_ip ? _ip_address_to_number($end_ip) : $start_num;
    }

    # Guarantee that the start <= end
    if ( $end_num < $start_num ) {
        ( $start_num, $end_num ) = ( $end_num, $start_num );
    }

    return ( $start_num, $end_num );
}


sub _ip_address_to_number {

    return unpack 'N', pack 'C4', split '\.', shift;
}

1;

__END__

=pod

=head1 NAME

Net::IPAddress::Filter - A compact and fast IP Address range filter

=head1 VERSION

version 20140113

=head1 SYNOPSIS

    my $filter = Net::IPAddress::Filter->new();

    #
    # Simple usage:
    #
    $filter->add_range('10.0.0.10', '10.0.0.50');
    $filter->add_range('192.168.1.1');
    print "In filter\n" if $filter->in_filter('10.0.0.25');

    #
    # CIDR syntax
    #
    $filter->add_range('172.168.0.0/24');
    # Equivalent to:
    $filter->add_range('172.168.0.0', '172.168.0.255');

    #
    # Annotated ranges
    #
    $filter->add_range_with_value('IANA-reserved range', '10.0.0.0', '10.255.255.255');
    my $array_ref = $filter->get_matches('10.128.0.0'); # [ 'IANA-reserved range' ]

=head1 DESCRIPTION

Net::IPAddress::Filter can be used to check if a given IP address is contained
in a set of filtered ranges. A range can contain any number of addresses, and
ranges can overlap.

Net::IPAddress::Filter uses the XS module L<Set::IntervalTree> under the hood.
An Interval Tree is a data structure optimised for fast insertions and searches
of ranges, so sequential scans are avoided. The XS tree data structure is more
compact than a pure Perl version of the same.

In testing on an AMD Athlon(tm) 64 X2 Dual Core Processor 4200+,
Net::IPAddress::Filter did about 60k range inserts per second, and about 140k
lookups per second. The process memory size grew by about 1MB per 10,000 ranges
inserted.

=head1 METHODS

=head2 new ( )

Constructs new blank filter object.

Expects:
    None.

Returns:
    Blessed filter object.

=head2 add_range( )

Add a range of IP addresses to the filter.

The range can be specified in three ways.

    1) As a single IP address.

    2) As a pair of IP addresses.

    3) As a single IP address with a CIDR suffix. In this case, any second IP
    address passed in by the caller will be ignored.

Expects:
    $start_ip - A dotted quad IP address string with optional CIDR suffix.
    $end_ip   - An optional dotted quad IP address string. Defaults to $start_ip.

Returns:
    1 if it didn't die in the attempt - insert() returns undef.

=head2 add_range_with_value( )

Add a range of IP addresses to the filter, plus associate a scalar value with
that range.

I couldn't think of a neat way to handle an optional value and an optional
range end in the same method, otherwise I would have put this in add_range().

Expects:
    $value    - A perl scalar to associate with this range.
    $start_ip - A dotted quad IP address string with optional CIDR suffix.
    $end_ip   - An optional dotted quad IP address string. Defaults to $start_ip.

Returns:
    1 if it didn't die in the attempt - insert() returns undef.

=head2 in_filter( )

Test whether a given IP address is in one of the ranges in the filter.

Expects:
    $test_ip - A dotted quad IP address string.

Returns:
    Number of ranges which span the test IP.

=head2 get_matches( )

Find any matching ranges for a given IP address. Each range holds a value field,
and these values will be returned.

Expects:
    $test_ip - A dotted quad IP address string.

Returns:
    The value fields for any ranges spanning the test IP.

=head1 FUNCTIONS

=head2 _get_start_and_end_numbers( )

Utility function to convert the given IP addresses into numbers. It handles
CIDR, and optional or out-of-order args.

Expects:
    $start_ip - A dotted quad IP address string with optional CIDR suffix.
    $end_ip   - An optional dotted quad IP address string. Defaults to $start_ip.

Returns:
    Ordered pair of integers.

=head2 _ip_address_to_number( )

Utility function to convert a dotted quad IP address to a number.

TODO: Handle IPv6 addresses as well.

Expects:
    A dotted quad IP address string.

Returns:
    The integer representation of the IP address.

=head1 CAVEATS AND TIPS

=over 4

=item *

L<Set::IntervalTree> versions < 0.03 have a known bug where

in_filter('128.0.0.0') will give a false positive if there are any ranges in
the filter. 128.0.0.0 is 2^31. This is fixed in version 0.03 onwards.

=back

=head1 TODO

=over 4

=item *

Support for IPv6 Addresses. This would need a lot of work, as

Set::IntervalTree uses long ints internally, and IPv6 needs 128-bit numbers.

=back

=head1 SEE ALSO

=over 4

=item *

L<Config::IPFilter> - Moose-based pure Perl IP address filter.

=item *

L<Net::BitTorrent::Network::IPFilter> - Moose-based pure Perl IP address filter.

=item *

L<NET::IPFilter> - Pure Perl extension for Accessing eMule / Bittorrent

IPFilter.dat Files and checking a given IP against this ipfilter.dat IP Range.

=back

=head1 BUGS OR FEATURE REQUESTS

See F<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-IPAddress-Filter>
to report and view bugs, or to request features.

Alternatively, email F<bug-Net-IPAddress-Filter@rt.cpan.org>

=head1 REPOSITORY

L<Net::IPAddress::Filter> is hosted on github at F<https://github.com/d5ve/p5-Net-IPAddress-Filter.git>

=head1 AUTHOR

Dave Webb <Net-IPAddress-Filter@d5ve.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Dave Webb.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
