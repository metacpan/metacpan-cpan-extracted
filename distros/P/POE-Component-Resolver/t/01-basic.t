#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 4;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Resolver qw(AF_INET AF_INET6);

my $r4 = POE::Component::Resolver->new(
	max_resolvers => 1,
	idle_timeout  => 1,
	af_order      => [ AF_INET ],
);

# Try to detect whether we can resolve IPv6 addresses at all.

use Socket qw(getaddrinfo);
my $has_ipv6 = do {
	my ($error, @addresses) = getaddrinfo(
		"ipv6.test-ipv6.com", "www", { family => AF_INET6 }
	);
	($error or not @addresses) ? 0 : 1;
};

# If we can't, don't bother setting up resolvers for them.

my ($r6, $r46, $r64);
if ($has_ipv6) {
	$r6 = POE::Component::Resolver->new(
		max_resolvers => 1,
		idle_timeout  => 1,
		af_order      => [ AF_INET6 ],
	);

	$r46 = POE::Component::Resolver->new(
		max_resolvers => 1,
		idle_timeout  => 1,
		af_order      => [ AF_INET, AF_INET6 ],
	);

	$r64 = POE::Component::Resolver->new(
		max_resolvers => 1,
		idle_timeout  => 1,
		af_order      => [ AF_INET6, AF_INET ],
	);
}

# TODO - Not robust to try a single remote host.  I fully expect this
# to bite me later, unless someone wants to take a shot at it.

my $host = 'ipv6-test.com';
my $tcp  = getprotobyname("tcp");
my $service = $^O eq 'solaris' ? 80 : 'http';

POE::Session->create(
	inline_states => {
		_start => sub {
			$r4->resolve(
				host    => $host,
				service => $service,,
				hints   => { protocol => $tcp },
				misc    => [ AF_INET ],
			) or die $!;

			SKIP: {
				skip("IPv6 not detected; skipping IPv6 tests", 3) unless $has_ipv6;

				$r6->resolve(
					host    => $host,
					service => $service,
					hints   => { protocol => $tcp },
					misc    => [ AF_INET6 ],
				) or die $!;

				$r46->resolve(
					host    => $host,
					service => $service,
					hints   => { protocol => $tcp },
					misc    => [ AF_INET, AF_INET6 ],
				) or die $!;

				$r64->resolve(
					host    => $host,
					service => $service,
					hints   => { protocol => $tcp },
					misc    => [ AF_INET6, AF_INET ],
				) or die $!;
			}
		},

		resolver_response => sub {
			my ($error, $addresses, $request) = @_[ARG0..ARG2];

			foreach my $a (@$addresses) {
				diag("$request->{host} = ", scalar($r4->unpack_addr($a)));
			}

			my $expected_families = $request->{misc};

			my @got_families = map { $_->{family} } @$addresses;

			my $i = $#got_families;
			while ($i > 0 and $i--) {
				splice(@got_families, $i, 1) if (
					$got_families[$i] == $got_families[$i+1]
				);
			}

			is_deeply(
				\@got_families,
				$expected_families,
				"address families are as expected (@$expected_families)",
			);
		},

		_stop => sub { undef }, # for ASSERT_DEFAULT
	},
);

POE::Kernel->run();
