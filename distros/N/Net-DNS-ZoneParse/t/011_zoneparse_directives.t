# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DNS-ZoneParse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
use Test::Deep;
BEGIN { use_ok('Net::DNS::ZoneParse') };

#########################

my $exporg = noclass(superhashof( {
			name => "example.com",
			class => "IN",
			type => "NS",
			nsdname => "ns1.example.com",
		}));
my $lname = noclass(superhashof( {
			name => "example.com",
			class => "IN",
			type => "A",
			address => "10.0.0.3",
		}));
my $cname = noclass(superhashof( {
			name => "foo.example.com",
			class => "IN",
			ttl => 3600,
			type => "CNAME",
			cname => "bar.example.com",
		}));
my $include = noclass(superhashof({
			name => "example.com",
			class => "",
			ttl => 1234,
			type => "A",
			address => "10.0.0.2",
		}));
my $ttl = noclass(superhashof( {
			name => "alpha.noexample.com",
			class => "IN",
			type => "MX",
			ttl => 1234,
			preference => 5,
			exchange => "foo.example.com",
		}));
my $generate = noclass([
	superhashof( {
			name => "5.example.com",
			class => "IN",
			type => "A",
			address => "10.0.0.5",
		}),
	superhashof( {
			name => "6.example.com",
			class => "IN",
			type => "A",
			address => "10.0.0.6",
		}),
	superhashof( {
			name => "7.example.com",
			class => "IN",
			type => "A",
			address => "10.0.0.7",
		}),
	]);

my $zoneparse = Net::DNS::ZoneParse->new();
my $rr = $zoneparse->parse(\*DATA);

cmp_deeply($rr->[0], $exporg, "expending @ to origin");
cmp_deeply($rr->[1], $lname, "exanding empty name to last used");
cmp_deeply($rr->[2], $cname, "origin test for CNAME");
cmp_deeply($rr->[3], $include, "include t/011_inner.db");
cmp_deeply($rr->[4], $ttl, "test ttl and origin for MX");
cmp_deeply([$rr->[5], $rr->[6], $rr->[7]], $generate, "generate IN A");

__END__
$ORIGIN example.com
$TTL 1234

@	IN	NS	ns1
	IN	A	10.0.0.3
foo IN 3600 CNAME bar
$INCLUDE t/011_inner.db
alpha.noexample.com. IN MX 5 foo
$GENERATE 5-7 $ IN A 10.0.0.$

