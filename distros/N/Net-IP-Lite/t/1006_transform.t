use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

sub test_transform {
	my ($addr, $opts) = @_;
	my $ip = Net::IP::Lite->new($addr) || die 'Failed to construct Net::IP::Lite';
	return $ip->transform($opts);
}

my $count = 0;

dies_ok  { Net::IP::Lite->new('::')->transform(1) } 'Die when $opts is not a hash'; $count++;
lives_ok { Net::IP::Lite->new('::')->transform()  } 'Must not die when $opts is not specified'; $count++;

$count += scalar @short_ipv6;
for my $addr (@short_ipv6) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "Shorten IPv6: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @short_ipv6_rev;
for my $addr (@short_ipv6_rev) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "Shorten and reverse IPv6: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @expand_ipv6;
for my $addr (@expand_ipv6) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "Expand IPv6: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @expand_ipv6_rev;
for my $addr (@expand_ipv6_rev) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "Expand and reverse IPv6: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @short_ipv4;
for my $addr (@short_ipv4) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "Shorten IPv4: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @short_ipv4_rev;
for my $addr (@short_ipv4_rev) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "Shorten and reverse IPv4: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @expand_ipv4;
for my $addr (@expand_ipv4) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "Expand IPv4: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @expand_ipv4_rev;
for my $addr (@expand_ipv4_rev) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "Expand and reverse IPv4: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @to_ipv6;
for my $addr (@to_ipv6) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv6 conversion: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @to_ipv6_rev;
for my $addr (@to_ipv6_rev) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv6 conversion and reverse: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @to_ipv4;
for my $addr (@to_ipv4) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv4 conversion: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @to_ipv4_rev;
for my $addr (@to_ipv4_rev) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv4 conversion and reverse: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @to_ipv6ipv4;
for my $addr (@to_ipv6ipv4) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv6IPv4 conversion: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @to_ipv6ipv4_rev;
for my $addr (@to_ipv6ipv4_rev) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv6IPv4 conversion and reverse: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @format_ipv4;
for my $addr (@format_ipv4) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv4 format: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @format_ipv4_rev;
for my $addr (@format_ipv4_rev) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv4 format and reverse: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @format_ipv6;
for my $addr (@format_ipv6) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv4 format: '$addr->[0]' -> '$addr->[1]'";
}

$count += scalar @format_ipv6_rev;
for my $addr (@format_ipv6_rev) {
	ok test_transform($addr->[0], $addr->[2]) eq $addr->[1], "IPv4 format and reverse: '$addr->[0]' -> '$addr->[1]'";
}

done_testing($count);
