use strict;
use warnings;

use Test::More 1;

use_ok 'Net::CIDR';

subtest 'cidr2octets' => sub {
    my @octet_list = Net::CIDR::cidr2octets("10.0.0.0/14", "192.168.0.0/24");

    push @octet_list, Net::CIDR::cidr2octets("::dead:beef:0:0/110");

    my @res = qw(
		10.0    10.1    10.2    10.3    192.168.0
		0000:0000:0000:0000:dead:beef:0000
		0000:0000:0000:0000:dead:beef:0001
		0000:0000:0000:0000:dead:beef:0002
		0000:0000:0000:0000:dead:beef:0003
	);

	is_deeply \@octet_list, \@res;
};

subtest 'addr2cidr' => sub {
	subtest 'basic' => sub {
		my @cidrs = Net::CIDR::addr2cidr('192.168.0.31');
		my @expected = split /\s+/, "192.168.0.31/32 192.168.0.30/31 192.168.0.28/30 192.168.0.24/29 192.168.0.16/28 192.168.0.0/27 192.168.0.0/26 192.168.0.0/25 192.168.0.0/24 192.168.0.0/23 192.168.0.0/22 192.168.0.0/21 192.168.0.0/20 192.168.0.0/19 192.168.0.0/18 192.168.0.0/17 192.168.0.0/16 192.168.0.0/15 192.168.0.0/14 192.168.0.0/13 192.160.0.0/12 192.160.0.0/11 192.128.0.0/10 192.128.0.0/9 192.0.0.0/8 192.0.0.0/7 192.0.0.0/6 192.0.0.0/5 192.0.0.0/4 192.0.0.0/3 192.0.0.0/2 128.0.0.0/1 0.0.0.0/0";
		is_deeply \@cidrs, \@expected;
	};

	# https://blog.urth.org/2021/03/29/security-issues-in-perl-ip-address-distros/
	subtest 'leading zero' => sub {
		my @ips = Net::CIDR::addr2cidr('010.0.0.1');
		my $leading = grep { /\b0\d/ } @ips;
		is $leading, 0, 'no IPs in 010.0.0.1 have extra leading zeros'
			or diag join "\n", @ips;
	};
};

subtest 'cidr2range' => sub {
	subtest 'ipv4' => sub {
		my @ranges = Net::CIDR::cidr2range("192.168.0.0/16");
		is scalar @ranges, 1, 'there is one item for cidr2range';
		is $ranges[0], "192.168.0.0-192.168.255.255";
	};

	subtest 'ipv6' => sub {
		my @ranges = Net::CIDR::cidr2range('dead::beef::/46');
		is scalar @ranges, 1, 'there is one item for cidr2range';
		is $ranges[0], "dead:beef::-dead:beef:3:ffff:ffff:ffff:ffff:ffff";
	};
};

subtest 'cidrvalidate' => sub {
	subtest 'good' => sub {
		my @addrs = qw(
			192.168.0.1 ::ffff:192.168.0.1 192.168.0.0/24 ::ffff:192.168.0.0/120
			dead:beef:: dead:beef::/32 dead:beef::/120 1:1:000f:01:65:e:1111:eeee
			fe80:0:120::/44
			2001:4860:4860:0:0:0:0:8888 2001:4860:4860::8888
			2001:4860:4860:1:0:1:1:8888
			2001:4860:4860:0:1:0:1:8888
			);
		foreach my $addr (@addrs) {
			ok Net::CIDR::cidrvalidate($addr), "$addr validates";
		}
	};

	subtest 'bad' => sub {
		my @addrs = qw(
			192.168.0.1/24 ::ffff:192.168.0.1/120 dead:beef::/31
			);
		foreach my $addr (@addrs) {
			ok ! Net::CIDR::cidrvalidate($addr), "$addr does not validate";
		}
	};
};

subtest 'cidrlookup' => sub {
	subtest 'only ipv4' => sub {
		my @only4 = qw(
			10.0.0.0/24
			10.0.1.0/24
		);
		is Net::CIDR::cidrlookup("10.0.0.1",    @only4), 1, '10.0.0.1 returns true for @only4';
		is Net::CIDR::cidrlookup("10.0.10.1",   @only4), 0, '10.0.10.1 returns false for @only4';
		is Net::CIDR::cidrlookup("2001:db8::1", @only4), 0, '2001:db8::1 returns false for @only4';
    };

	subtest 'only ipv6' => sub {
		my @only6 = qw(
			2001:db8::/64
			2001:db8:1::/64
		);
		is Net::CIDR::cidrlookup("2001:db8::1",   @only6), 1, "2001:db8::1 returns true for @only6";
		is Net::CIDR::cidrlookup("2001:db8:a::1", @only6), 0, "2001:db8:a::1 returns false for @only6";
		is Net::CIDR::cidrlookup("10.0.0.1",      @only6), 0, "10.0.0.1 returns false for @only6";
    };

	subtest 'ipv4 and ipv6' => sub {
		my @dualstack = qw(
			10.0.2.0/24
			2001:db8:2::/64
		);
		is Net::CIDR::cidrlookup("10.0.2.1",       @dualstack), 1, "10.0.2.1 returns true for @dualstack";
		is Net::CIDR::cidrlookup("10.0.20.1",      @dualstack), 0, "10.0.20.1 returns false for @dualstack";
		is Net::CIDR::cidrlookup("2001:db8:2::1",  @dualstack), 1, "2001:db8:2::1 returns true for @dualstack";
		is Net::CIDR::cidrlookup("2001:db8:20::1", @dualstack), 0, "2001:db8:20::1 returns false for @dualstack";
    };
};

done_testing();
