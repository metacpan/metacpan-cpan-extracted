use Test::More;
use Net::Subnet;

my @subnets = qw(
    2001:db8:10::/48
    2001:db8:10:5::/64
    ::1/128
    192.168.0.0/22
    2001:db8:8000::/34
);

my %matches = qw(
    2001:db8:10::123:123:123:1234           2001:db8:10::/48
    2001:db8:10::                           2001:db8:10::/48
    2001:db8:10:ffff:ffff:ffff:ffff:ffff    2001:db8:10::/48
    2001:db8:10:5::1                        2001:db8:10:5::/64
    2001:db8:8000::1                        2001:db8:8000::/34
    ::1                                     ::1/128
    192.168.0.5                             192.168.0.0/22
    192.168.1.5                             192.168.0.0/22
    192.168.2.5                             192.168.0.0/22
    192.168.3.5                             192.168.0.0/22
);

my @nonmatches = qw(
    ::2
    ::0
    0.0.0.0
    ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
    255.255.255.255
    192.168.4.5
    2001:db8:11::1
    2001:db8:8::
    2001:db8:8::2
);


my @sorted_subnets = sort_subnets(@subnets);

my %seen;
for (@sorted_subnets) {
    if ($_ eq '2001:db8:10::/48') {
        ok($seen{'2001:db8:10:5::/64'}, "/64 sorts before /48");
    }
    $seen{$_}++;
}

my $matcher    = subnet_matcher(@subnets);
my $classifier = subnet_classifier(@sorted_subnets);

for (keys %matches) {
    ok($matcher->($_), "Matcher matches $_");
    is($classifier->($_), $matches{$_},
        "Classifier identifies $_ as belonging to $matches{$_}");
}

for (@nonmatches) {
    ok(!$matcher->($_), "Matcher returns false for $_");
    ok(!defined($classifier->($_)), "Classifier returns undef for $_");
}

done_testing;
