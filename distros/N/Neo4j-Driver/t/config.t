#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings;


# The Neo4j::Driver package itself mostly deals with configuration
# in the form of the server URL, auth credentials and other options.

use Neo4j_Test;

# Report the Network error if there is one (to aid debugging),
# but don't skip any of the tests below.
unless ( $ENV{NO_NETWORK_TESTING} or Neo4j_Test->driver() ) {
	diag $Neo4j_Test::error;
}

my ($d, $r);

plan tests => 10 + 1;


subtest 'config read/write' => sub {
	plan tests => 7;
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver';
	# write and read single options
	my $timeout = exp(1);
	lives_and { is $d->config(timeout => $timeout), $d; } 'set timeout';
	lives_and { is $d->config('timeout'), $timeout; } 'get timeout';
	lives_and { is $d->config('ca_file'), undef; } 'get unset ca_file';
	# write and read multiple options
	my $ca_file = '/dev/null';
	my @options = (timeout => $timeout * 2, ca_file => $ca_file);
	lives_and { is $d->config(@options), $d; } 'set two options';
	lives_and { is $d->config('timeout'), $timeout * 2; } 'get timeout 2nd';
	lives_and { is $d->config('ca_file'), $ca_file; } 'get ca_file';
};


subtest 'direct hash access' => sub {
	# Direct hash access is known to be used in code in the wild, even
	# though it was not officially supported at the time. We currently
	# do support it, but only for the timeout (using the old name) and
	# without any guarantees of future support.
	plan tests => 4;
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver';
	my $timeout = sqrt(2);
	$d->{http_timeout} = $timeout;
	lives_and { is $d->config('timeout'), $timeout; } 'get timeout';
	lives_ok { $d->config(timeout => $timeout * 2); } 'set timeout lives';
	is $d->{http_timeout}, $timeout * 2, 'timeout set';
};


subtest 'config illegal args' => sub {
	plan tests => 6;
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver';
	throws_ok {
		 $d->config();
	} qr/\bUnsupported\b/i, 'no args';
	throws_ok {
		 $d->config( timeout => 1,5 );
	} qr/\bOdd number of elements\b/i, 'illegal hash';
	throws_ok {
		 $d->config( 'http_timeout' );
	} qr/\bUnsupported\b.*\bhttp_timeout\b/i, 'illegal name get';
	throws_ok {
		 $d->config( http_timeout => 1 );
	} qr/\bUnsupported\b.*\bhttp_timeout\b/i, 'illegal name set single';
	throws_ok {
		 $d->config( aaa => 1, bbb => 2 );
	} qr/\bUnsupported\b.*\baaa\b.*\bbbb\b/i, 'illegal name set multi';
};


subtest 'uri variants' => sub {
	plan tests => 16;
	# http scheme (default)
	lives_ok { $d = 0; $d = Neo4j::Driver->new('HTTP://TEST:7474'); } 'http uppercase lives';
	lives_and { is $d->{uri}->scheme, 'http'; } 'http uppercase scheme';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://test1:9999'); } 'http full uri lives';
	lives_and { is $d->{uri}, 'http://test1:9999'; } 'http full uri';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://test2'); } 'http default port lives';
	lives_and { is $d->{uri}, 'http://test2:7474'; } 'http default port';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http:'); } 'http scheme only lives';
	lives_and { is $d->{uri}, 'http://localhost:7474'; } 'http scheme only';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://'); } 'http scheme only long lives';
	lives_and { is $d->{uri}, 'http://localhost:7474'; } 'http scheme only long';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('test4'); } 'host only lives';
	lives_and { is $d->{uri}, 'http://test4:7474'; } 'host only';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('//localhost'); } 'network-path ref lives';
	lives_and { is $d->{uri}, 'http://localhost:7474'; } 'network-path ref only';
	lives_ok { $d = 0; $d = Neo4j::Driver->new(''); } 'empty lives';
	lives_and { is $d->{uri}, 'http://localhost:7474'; } 'empty';
};


subtest 'non-http uris' => sub {
	plan tests => 12;
	# https scheme
	lives_ok { $d = 0; $d = Neo4j::Driver->new('https://test6:9993'); } 'https full uri lives';
	lives_and { is $d->{uri}, 'https://test6:9993'; } 'https full uri';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('https://test7'); } 'https default port lives';
	lives_and { is $d->{uri}, 'https://test7:7473'; } 'https default port';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('https:'); } 'https scheme only lives';
	lives_and { is $d->{uri}, 'https://localhost:7473'; } 'https scheme only';
	# bolt scheme
	lives_ok { $d = 0; $d = Neo4j::Driver->new('bolt://test:9997'); } 'bolt full uri lives';
	is $d->{uri}, 'bolt://test:9997', 'bolt full uri';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('bolt://test9'); } 'bolt default port lives';
	is $d->{uri}, 'bolt://test9:7687', 'bolt default port';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('bolt:'); } 'bolt scheme only lives';
	is $d->{uri}, 'bolt://localhost:7687', 'bolt scheme only';
};


subtest 'unsupported uris' => sub {
	plan tests => 8;
	# unimplemented scheme (Casual Clusters)
	throws_ok {
		Neo4j::Driver->new('bolt+routing://test12');
	} qr/\bscheme\b.*\bunsupported\b/i, 'bolt+routing full uri';
	throws_ok {
		Neo4j::Driver->new('bolt+routing:');
	} qr/\bscheme\b.*\bunsupported\b/i, 'bolt+routing scheme only';
	throws_ok {
		Neo4j::Driver->new('neo4j://test12');
	} qr/\bscheme\b.*\bunsupported\b/i, 'neo4j full uri';
	throws_ok {
		Neo4j::Driver->new('neo4j:');
	} qr/\bscheme\b.*\bunsupported\b/i, 'neo4j scheme only';
	# unknown scheme
	throws_ok {
		Neo4j::Driver->new('unkown://test12');
	} qr/\bscheme\b.*\bunsupported\b/i, 'unknown full uri';
	throws_ok {
		Neo4j::Driver->new('unkown:');
	} qr/\bscheme\b.*\bunsupported\b/i, 'unknown scheme only';
	# illegal scheme
	throws_ok {
		Neo4j::Driver->new('ille*gal://test12');
	} qr/\bscheme\b.*\bunsupported\b/i, 'illegal full uri';
	throws_ok {
		Neo4j::Driver->new('ille*gal:');
	} qr/\bscheme\b.*\bunsupported\b/i, 'illegal scheme only';
};


subtest 'uris with path/query' => sub {
	plan tests => 8;
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://extra-slash/'); } 'path / lives';
	lives_and { is $d->{uri}, 'http://extra-slash:7474'; } 'path / removed';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://reverse/proxy/'); } 'path /proxy/ lives';
	lives_and { is $d->{uri}, 'http://reverse:7474/proxy/'; } 'path /proxy/ unchanged';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://reverse/?proxy'); } 'query /?proxy lives';
	lives_and { is $d->{uri}, 'http://reverse:7474/?proxy'; } 'query /?proxy unchanged';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://host/#fragment'); } 'fragment lives';
	lives_and { is $d->{uri}, 'http://host:7474'; } 'fragment removed';
};


subtest 'tls' => sub {
	plan tests => 7;
	my $ca_file = '8aA6EPsGYE7sbB7bLWiu.';  # doesn't exist
	lives_ok { $d = Neo4j::Driver->new('https://test/')->config(tls_ca => $ca_file); } 'create https with CA file';
	is $d->{tls_ca}, $ca_file, 'tls_ca';
	throws_ok { $d->session; } qr/\Q$ca_file\E/, 'https session fails with missing CA file';
	throws_ok {
		Neo4j::Driver->new('https://test/')->config(tls => 0)->session;
	} qr/\bHTTPS does not support unencrypted communication\b/i, 'no unencrypted https';
	lives_ok {
		$d = Neo4j::Driver->new('https://test/')->config(tls => 1);
		Neo4j_Test->transaction_unconnected($d);
	} 'encrypted https';
	ok $d->{tls}, 'tls';
	throws_ok {
		Neo4j::Driver->new('http://test/')->config(tls => 1)->session;
	} qr/\bHTTP does not support encrypted communication\b/i, 'no encrypted http';
};


subtest 'auth' => sub {
	plan tests => 2;
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://user:pass@test:9999'); } 'auth in full uri lives';
	lives_and { is $d->{uri}, 'http://user:pass@test:9999'; } 'auth in full uri';
};


subtest 'cypher filter' => sub {
	plan tests => 17;
	my ($t, @q);
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 1';
	lives_ok { $d->config(cypher_filter => 'params'); } 'set filter';
	lives_ok { $t = Neo4j_Test->transaction_unconnected($d); } 'new tx 1';
	@q = ('RETURN {`ab.`}, {c}, {cd}', 'ab.' => 17, c => 19, cd => 23);
	lives_ok { $r = 0; $r = $t->_prepare(@q); } 'prepare simple';
	is $r->{statement}, 'RETURN $`ab.`, $c, $cd', 'filtered simple';
	@q = ('CREATE (a) RETURN {}, {a:a}, {a}, [a]', a => 17);
	lives_ok { $r = 0; $r = $t->_prepare(@q); } 'prepare composite';
	is $r->{statement}, 'CREATE (a) RETURN {}, {a:a}, $a, [a]', 'filtered composite';
	lives_ok { $r = 0; $r = $t->_prepare('RETURN 42'); } 'prepare no params';
	is $r->{statement}, 'RETURN 42', 'filtered no params';
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 2';
	lives_ok { $d->config(cypher_filter => 'coffee'); } 'set filter unkown name';
	lives_ok { $t = Neo4j_Test->transaction_unconnected($d); } 'new tx 2';
	throws_ok {
		$r = 0; $r = $t->_prepare('RETURN 42');
	} qr/\bUnimplemented cypher filter\b/i, 'unprepared filter unkown name';
	# no filter (for completeness)
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 3';
	lives_ok { $t = Neo4j_Test->transaction_unconnected($d); } 'new tx 3';
	@q = ('RETURN {a}', a => 17);
	lives_ok { $r = 0; $r = $t->_prepare(@q); } 'prepare unfiltered';
	is $r->{statement}, 'RETURN {a}', 'unfiltered';
};


done_testing;
