# NAME

Net::CIDR::Set - Manipulate sets of IP addresses

# VERSION

version 0.16

# SYNOPSIS

```perl
use Net::CIDR::Set;

my $priv = Net::CIDR::Set->new( '10.0.0.0/8', '172.16.0.0/12',
  '192.168.0.0/16' );
for my $ip ( @addr ) {
  if ( $priv->contains( $ip ) ) {
    print "$ip is private\n";
  }
}
```

# DESCRIPTION

`Net::CIDR::Set` represents sets of IP addresses and allows standard
set operations (union, intersection, membership test etc) to be
performed on them.

In spite of the name it can work with sets consisting of arbitrary
ranges of IP addresses - not just CIDR blocks.

Both IPv4 and IPv6 addresses are handled - but they may not be mixed in
the same set. You may explicitly set the personality of a set:

```perl
my $ip4set = Net::CIDR::Set->new({ type => 'ipv4 }, '10.0.0.0/8');
```

Normally this isn't necessary - the set will guess its personality from
the first data that is added to it.

# ATTRIBUTES

## type

Either `ipv4`, `ipv6` or the name of a coder class.

See [Net::CIDR::Set::IPv4](https://metacpan.org/pod/Net%3A%3ACIDR%3A%3ASet%3A%3AIPv4) and [Net::CIDR::Set::IPv6](https://metacpan.org/pod/Net%3A%3ACIDR%3A%3ASet%3A%3AIPv6) for examples of
coder classes.

# METHODS

## new

Create a new Net::CIDR::Set. All arguments are optional. May be passed a
list of list of IP addresses or ranges which, if present, will be
passed to ["add"](#add).

The first argument may be a hash reference which will be inspected for
named options. Currently the only option that may be passed is ["type"](#type).

## invert

Invert (negate, complement) a set in-place.

```perl
my $set = Net::CIDR::Set->new;
$set->invert;
```

## copy

Make a deep copy of a set.

```perl
my $set2 = $set->copy;
```

## add

Add a number of addresses or ranges to a set.

```
$set->add(
  '10.0.0.0/8',
  '192.168.0.32-192.168.0.63',
  '127.0.0.1'
);
```

It is legal to add ranges that overlap with each other and/or with the
ranges already in the set. Overlapping ranges are merged.

## remove

Remove a number of addresses or ranges from a set.

```
$set->remove(
  '8.8.0.0/16',
  '158.152.1.58'
);
```

There is no requirement that the addresses being removed be members
of the set.

## merge

Merge the contents of other sets into this set.

```
$set = Net::CIDR::Set->new;
$set->merge($s1, $s2);
```

## contains

A synonmym for `contains_all`.

## contains\_all

Return true if the set contains all of the supplied addresses.
Given this set:

```perl
my $set = Net::CIDR::Set->new('244.188.12.0/8');
```

this condition is true:

```
if ( $set->contains_all('244.188.12.128/3') ) {
  # ...
}
```

while this condition is false:

```
if ( $set->contains_all('244.188.12.0/12') ) {
  # ...
}
```

## contains\_any

Return true if there is any overlap between the supplied
addresses/ranges and the contents of the set.

## complement

Return a new set that is the complement of this set.

```perl
my $inv = $set->complement;
```

## union

Return a new set that is the union of a number of sets. This is
equivalent to a logical OR between sets.

```perl
my $everything = $east->union($west);
```

## intersection

Return a new set that is the intersection of a number of sets. This is
equivalent to a logical AND between sets.

```perl
my $overlap = $north->intersection($south);
```

## xor

Return a new set that is the exclusive-or of existing sets.

```perl
my $xset = $this->xor($that);
```

The resulting set will contain all addresses that are members of one set
but not the other.

## diff

Return a new set containing all the addresses that are present in this
set but not another.

```perl
my $diff = $this->diff($that);
```

## is\_empty

Return a true value if the set is empty.

```
if ( $set->is_empty ) {
  print "Nothing there!\n";
}
```

## superset

Return true if this set is a superset of the supplied set.

## subset

Return true if this set is a subset of the supplied set.

## equals

Return true if this set is identical to another set.

```
if ( $set->equals($foo) ) {
  print "We have the same addresses.\n";
}
```

## iterate\_addresses

Return an iterator (a closure) that will return each of the addresses in
the set in ascending order. This code

```perl
my $set = Net::CIDR::Set->new('192.168.37.0/24');
my $iter = $set->iterate_addresses;
while ( my $ip = $iter->() ) {
  print "Got $ip\n";
}
```

outputs 256 distinct addresses from 192.168.37.0 to 192.168.27.255.

## iterate\_cidr

Return an iterator (a closure) that will return each of the CIDR blocks
in the set in ascending order. This code

```perl
my $set = Net::CIDR::Set->new('192.168.37.9-192.168.37.134');
my $iter = $set->iterate_cidr;
while ( my $cidr = $iter->() ) {
  print "Got $cidr\n";
}
```

outputs

```
Got 192.168.37.9
Got 192.168.37.10/31
Got 192.168.37.12/30
Got 192.168.37.16/28
Got 192.168.37.32/27
Got 192.168.37.64/26
Got 192.168.37.128/30
Got 192.168.37.132/31
Got 192.168.37.134
```

This is the most compact CIDR representation of the set because its
limits don't fall on convenient CIDR boundaries.

## iterate\_ranges

Return an iterator (a closure) that will return each of the ranges
in the set in ascending order. This code

```perl
my $set = Net::CIDR::Set->new(
  '192.168.37.9-192.168.37.134',
  '127.0.0.1',
  '10.0.0.0/8'
);
my $iter = $set->iterate_ranges;
while ( my $range = $iter->() ) {
  print "Got $range\n";
}
```

outputs

```
Got 10.0.0.0/8
Got 127.0.0.1
Got 192.168.37.9-192.168.37.134
```

## as\_array

Convenience method that gathers all of the output from one of the
iterators above into an array.

```perl
my @ranges = $set->as_array( $set->iterate_ranges );
```

Normally you will use one of `as_address_array`, `as_cidr_array` or
`as_range_array` instead.

## as\_address\_array

Return an array containing all of the distinct addresses in a set. Note
that this may very easily create a very large array. At the time of
writing it is, for example, unlikely that you have enough memory for an
array containing all of the possible IPv6 addresses...

## as\_cidr\_array

Return an array containing all of the distinct CIDR blocks in a set.

## as\_range\_array

Return an array containing all of the ranges in a set.

## as\_string

Return a compact string representation of a set.

# Retrieving Set Contents

The following methods allow the contents of a set to be retrieved in
various representations. Each of the following methods accepts an
optional numeric argument that controls the formatting of the returned
addresses. It may take one of the following values:

- `0`

    Format each range of addresses as compactly as possible. If the range
    contains only a single address format it as such. If it can be
    represented as a single CIDR block use CIDR representation (&lt;ip>/&lt;mask>)
    otherwise format it as an arbitrary range (&lt;start>-&lt;end>).

- `1`

    Always format as either a CIDR block or an arbitrary range even if the
    range is just a single address.

- `2`

    Always use arbitrary range format (&lt;start>-&lt;end>) even if the range is a
    single address or a legal CIDR block.

Here's an example of the different formatting options:

```perl
my $set = Net::CIDR::Set->new( '127.0.0.1', '192.168.37.0/24',
  '10.0.0.11-10.0.0.17' );

for my $fmt ( 0 .. 2 ) {
  print "Using format $fmt:\n";
  print "  $_\n" for $set->as_range_array( $fmt );
}
```

And here's the output from that code:

```
Using format 0:
  10.0.0.11-10.0.0.17
  127.0.0.1
  192.168.37.0/24
Using format 1:
  10.0.0.11-10.0.0.17
  127.0.0.1/32
  192.168.37.0/24
Using format 2:
  10.0.0.11-10.0.0.17
  127.0.0.1-127.0.0.1
  192.168.37.0-192.168.37.255
```

Note that this option never affects the addresses that are returned;
only how they are formatted.

For most purposes the formatting argument can be omitted; it's default
value is `0` which provides the most general formatting.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Net-CIDR-Set](https://github.com/robrwo/perl-Net-CIDR-Set)
and may be cloned from [git://github.com/robrwo/perl-Net-CIDR-Set.git](git://github.com/robrwo/perl-Net-CIDR-Set.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://rt.cpan.org/Public/Dist/Display.html?Name=Net-CIDR-Set](https://rt.cpan.org/Public/Dist/Display.html?Name=Net-CIDR-Set)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see `SECURITY.md` for instructions how to
report security vulnerabilities

# AUTHOR

Andy Armstrong <andy@hexten.net>

The current maintainer is Robert Rothenberg <rrwo@cpan.org>.

The encode and decode routines were stolen en masse from Douglas Wilson's [Net::CIDR::Lite](https://metacpan.org/pod/Net%3A%3ACIDR%3A%3ALite).

# CONTRIBUTORS

- Brian Gottreu <gottreu@cpan.org>
- Robert Rothenberg <rrwo@cpan.org>
- Stig Palmquist <stigtsp@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2009, 2014, 2025 by Message Systems, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
