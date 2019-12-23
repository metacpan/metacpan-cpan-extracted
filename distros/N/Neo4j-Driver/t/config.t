#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

my $driver;
use Neo4j::Test;
BEGIN {
	unless ($driver = Neo4j::Test->driver) {
		print qq{1..0 # SKIP no connection to Neo4j server\n};
		exit;
	}
}


# The Neo4j::Driver package itself mostly deals with configuration
# in the form of the server URL, auth credentials and other options.

use Test::More 0.96 tests => 6 + 1;
use Test::Exception;
use Test::Warnings;


my ($d, $r);


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
	plan tests => 18;
	# http scheme (default)
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://test1:9999'); } 'http full uri lives';
	lives_and { is $d->{uri}, 'http://test1:9999'; } 'http full uri';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://test2'); } 'http default port lives';
	lives_and { is $d->{uri}, 'http://test2:7474'; } 'http default port';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http:'); } 'http scheme only lives';
	lives_and { is $d->{uri}, 'http://localhost:7474'; } 'http scheme only';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('test4'); } 'host only lives';
	lives_and { is $d->{uri}, 'http://test4:7474'; } 'host only';
	lives_ok { $d = 0; $d = Neo4j::Driver->new(''); } 'empty lives';
	lives_and { is $d->{uri}, 'http://localhost:7474'; } 'empty';
	# https scheme
	lives_ok { $d = 0; $d = Neo4j::Driver->new('https://test6:9993'); } 'https full uri lives';
	lives_and { is $d->{uri}, 'https://test6:9993'; } 'https full uri';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('https://test7'); } 'https default port lives';
	lives_and { is $d->{uri}, 'https://test7:7473'; } 'https default port';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('https:'); } 'https scheme only lives';
	lives_and { is $d->{uri}, 'https://localhost:7473'; } 'https scheme only';
	# bolt scheme
	eval { $d = 0; $d = Neo4j::Driver->new('bolt://test9'); };
	ok $@ =~ m/Neo4j::Bolt/ || ! $@ && $d->{uri} eq 'bolt://test9:7687', 'bolt default port';
	eval { $d = 0; $d = Neo4j::Driver->new('bolt:'); };
	ok $@ =~ m/Neo4j::Bolt/ || ! $@ && $d->{uri} eq 'bolt://localhost:7687', 'bolt scheme only';
};


subtest 'illegal uris' => sub {
	plan tests => 2;
	# illegal scheme
	throws_ok {
		Neo4j::Driver->new('illegal://test12');
	} qr/\bOnly\b.*\bhttp\b.*\bsupported\b/i, 'illegal full uri';
	throws_ok {
		Neo4j::Driver->new('illegal:');
	} qr/\bOnly\b.*\bhttp\b.*\bsupported\b/i, 'illegal scheme only';
};


subtest 'cypher filter' => sub {
	plan tests => 17;
	my ($t, @q);
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 1';
	lives_ok { $d->config(cypher_filter => 'params'); } 'set filter';
	lives_ok { $t = Neo4j::Driver::Transaction->new( $d->session ); } 'new tx 1';
	@q = ('RETURN {ab}, {c}, {cd}', ab => 17, c => 19, cd => 23);
	lives_ok { $r = 0; $r = $t->_prepare(@q); } 'prepare simple';
	is $r->{statement}, 'RETURN $ab, $c, $cd', 'filtered simple';
	@q = ('CREATE (a) RETURN {}, {a:a}, {a}, [a]', a => 17);
	lives_ok { $r = 0; $r = $t->_prepare(@q); } 'prepare composite';
	is $r->{statement}, 'CREATE (a) RETURN {}, {a:a}, $a, [a]', 'filtered composite';
	lives_ok { $r = 0; $r = $t->_prepare('RETURN 42'); } 'prepare no params';
	is $r->{statement}, 'RETURN 42', 'filtered no params';
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 2';
	lives_ok { $d->config(cypher_filter => 'coffee'); } 'set filter unkown name';
	lives_ok { $t = 0; $t = Neo4j::Driver::Transaction->new( $d->session ); } 'new tx 2';
	throws_ok {
		$r = 0; $r = $t->_prepare('RETURN 42');
	} qr/\bUnimplemented cypher filter\b/i, 'unprepared filter unkown name';
	# no filter (for completeness)
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 3';
	lives_ok { $t = 0; $t = Neo4j::Driver::Transaction->new( $d->session ); } 'new tx 3';
	@q = ('RETURN {a}', a => 17);
	lives_ok { $r = 0; $r = $t->_prepare(@q); } 'prepare unfiltered';
	is $r->{statement}, 'RETURN {a}', 'unfiltered';
};


done_testing;
