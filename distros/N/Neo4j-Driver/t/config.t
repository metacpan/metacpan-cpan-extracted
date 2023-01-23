#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings qw(warning);


# The Neo4j::Driver package itself mostly deals with configuration
# in the form of the server URL, auth credentials and other options.

use Neo4j_Test;
use Neo4j_Test::MockHTTP;

my ($d, $r, $w);

plan tests => 16 + 1;


subtest 'config read/write' => sub {
	plan tests => 12;
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver';
	# write and read single options
	my $timeout = exp(1);
	lives_and { is $d->config(timeout => $timeout), $d; } 'set timeout';
	lives_and { is $d->config('timeout'), $timeout; } 'get timeout';
	lives_and { is $d->config('trust_ca'), undef; } 'get unset trust_ca';
	lives_and { is $d->config({trust_ca => ''}), $d; } 'set trust_ca ref';
	lives_and { is $d->config('trust_ca'), ''; } 'get trust_ca ref';
	# write and read multiple options
	my $ca_file = '/dev/null';
	my @options = (timeout => $timeout * 2, trust_ca => $ca_file);
	lives_and { is $d->config(@options), $d; } 'set two options';
	lives_and { is $d->config('timeout'), $timeout * 2; } 'get timeout 2nd';
	lives_and { is $d->config('trust_ca'), $ca_file; } 'get trust_ca 2';
	@options = (timeout => $timeout * 3, trust_ca => '');
	lives_and { is $d->config({@options}), $d; } 'set two options ref';
	lives_and { is $d->config('timeout'), $timeout * 3; } 'get timeout ref';
	lives_and { is $d->config('trust_ca'), ''; } 'get trust_ca 3 ref';
};


subtest 'constructor config' => sub {
	plan tests => 10;
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver default lives';
	lives_and { is $d->{http_timeout}, undef; } 'new driver default';
	lives_ok { $d = 0; $d = Neo4j::Driver->new({timeout => 1}); } 'new driver hashref lives';
	lives_and { is $d->{timeout}, 1; } 'new driver hashref';
	lives_and { like $d->{uri}, qr/\blocalhost\b/; } 'new driver default uri';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://test:10047'); } 'new driver uri lives';
	lives_and { is $d->{uri}, 'http://test:10047'; } 'new driver uri';
	lives_ok { $d = 0; $d = Neo4j::Driver->new({}); } 'new driver empty hashref lives';
	lives_and { like $d->{uri}, qr/\blocalhost\b/; } 'new driver empty hashref default uri';
	throws_ok { Neo4j::Driver->new({}, 0) } qr/\bmultiple arguments unsupported\b/i, 'extra arg';
};


subtest 'config illegal args' => sub {
	plan tests => 8;
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver';
	throws_ok {
		 $d->config();
	} qr/\bUnsupported\b/i, 'no args';
	throws_ok {
		 $d->config( {} );
	} qr/\bUnsupported\b/i, 'no opts';
	throws_ok {
		 $d->config( timeout => 1,5 );
	} qr/\bOdd number of elements\b/i, 'illegal hash';
	throws_ok {
		 $d->config( {}, 0 );
	} qr/\bUnsupported\b/i, 'extra arg';
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


subtest 'config/session sequence' => sub {
	plan tests => 8;
	lives_ok { $d = 0; $d = Neo4j::Driver->new->plugin(Neo4j_Test::MockHTTP->new) } 'new mock driver';
	lives_ok { $d->basic_auth(user => 'pw') } 'basic_auth before session';
	lives_ok { $d->config(auth => undef) } 'config before session';
	lives_ok { $d->session(database => 'dummy') } 'first session';
	lives_ok { $w = ''; $w = warning {
		$d->basic_auth(user => 'pw');
	}} 'basic_auth after session lives';
	like $w, qr/\bDeprecated sequence\b.*\bsession\b/i, 'basic_auth after session deprecated'
		or diag 'got warning(s): ', explain $w;
	throws_ok {
		$d->config(auth => undef);
	} qr/\bUnsupported sequence\b.*\bsession\b/i, 'config after session';
	lives_ok { $d->session(database => 'dummy') } 'second session';
};


subtest 'uri config' => sub {
	plan tests => 10;
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://test:10023'); } 'new driver lives';
	lives_and { is $d->config('uri'), 'http://test:10023'; } 'new driver get';
	lives_ok { $d = $d->config(timeout => 60); } 'other config set lives';
	lives_and { is $d->config('uri'), 'http://test:10023'; } 'other config no change';
	lives_ok { $d = $d->config(uri => 'http://test:10057'); } 'uri set lives';
	lives_and { is $d->config('uri'), 'http://test:10057'; } 'uri get';
	lives_ok { $d = $d->config(uri => undef); } 'uri undef lives';
	lives_and { is $d->config('uri'), 'http://localhost:7474'; } 'uri undef default';
	lives_ok { $d = 0; $d = Neo4j::Driver->new({uri => 'http://test:10059'}); } 'uri hashref lives';
	lives_and { is $d->config('uri'), 'http://test:10059'; } 'uri hashref get';
};


subtest 'uri variants' => sub {
	plan tests => 20;
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
	# long host names
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://foo.bar.test:10023'); } 'new driver fqdn lives';
	lives_and { is $d->config('uri'), 'http://foo.bar.test:10023'; } 'new driver fqdn';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('foo.bar.test'); } 'host only fqdn lives';
	lives_and { is $d->{uri}, 'http://foo.bar.test:7474'; } 'host only fqdn';
};


subtest 'uri literal ips' => sub {
	plan tests => 18;
	# IPv4 parsing
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://198.51.100.2:4000'); } 'IPv4 full uri lives';
	lives_and { is $d->{uri}, 'http://198.51.100.2:4000'; } 'IPv4 full uri';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('198.51.100.2'); } 'IPv4 only lives';
	lives_and { is $d->{uri}, 'http://198.51.100.2:7474'; } 'IPv4 only';
	throws_ok {
		Neo4j::Driver->new('198.51.100.2:7474');
	} qr/\bFailed to parse URI\b/i, 'IPv4 only with port dies';
	# IPv6 parsing
	my $ip;
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://[::1]:6000'); } 'IPv6 full uri lives';
	lives_and { is $d->{uri}, 'http://[::1]:6000'; } 'IPv6 full uri';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('::1'); } 'IPv6 only lives';
	lives_and { is $d->{uri}, 'http://[::1]:7474'; } 'IPv6 only';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('::'); } 'IPv6 default only lives';
	lives_and { is $d->{uri}, 'http://[::]:7474'; } 'IPv6 default only';
	$ip = '2001:db8:85a3:8d3:1319:fabe:360c:7348';
	lives_ok { $d = 0; $d = Neo4j::Driver->new("$ip"); } 'IPv6 long only lives';
	lives_and { is $d->{uri}, "http://[$ip]:7474"; } 'IPv6 long only';
	$ip = '64:ff9b:1:fffe::192.0.2.34';
	lives_ok { $d = 0; $d = Neo4j::Driver->new("[$ip]"); } 'IPv4/IPv6 translation lives';
	lives_and { is $d->{uri}, "http://[$ip]:7474"; } 'IPv4/IPv6 translation';
	$ip = '2001:DB8:0:0:01::AA';
	lives_ok { $d = 0; $d = Neo4j::Driver->new("//[$ip]"); } 'IPv6 non-canoncial lives';
	lives_and { like $d->{uri}, qr{^http://\[2001:db8:[01:]+:aa\]:7474$}i; } 'IPv6 non-canoncial';
	throws_ok {
		Neo4j::Driver->new("[$ip]:7474");
	} qr/\bFailed to parse URI\b/i, 'IPv6 literal only with port dies';
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
	plan tests => 9;
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
		Neo4j::Driver->new('://empty');
	} qr/\bFailed to parse URI\b/i, 'empty scheme';
	throws_ok {
		Neo4j::Driver->new('ille*gal://test12');
	} qr/\bscheme\b.*\bunsupported\b|\bFailed to parse URI\b/i, 'illegal full uri';
	throws_ok {
		Neo4j::Driver->new('ille*gal:');
	} qr/\bscheme\b.*\bunsupported\b|\bFailed to parse URI\b/i, 'illegal scheme only';
};


subtest 'uris with path/query' => sub {
	plan tests => 10;
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://extra-slash/'); } 'path / lives';
	lives_and { is $d->{uri}, 'http://extra-slash:7474'; } 'path / removed';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://reverse/proxy/'); } 'path /proxy/ lives';
	lives_and { is $d->{uri}, 'http://reverse:7474/proxy/'; } 'path /proxy/ unchanged';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://reverse/?proxy'); } 'query /?proxy lives';
	lives_and { is $d->{uri}, 'http://reverse:7474/?proxy'; } 'query /?proxy unchanged';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://fqdn.test/foo.com'); } 'fqdn path lives';
	lives_and { is $d->{uri}, 'http://fqdn.test:7474/foo.com'; } 'fqdn path unchanged';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://host/#fragment'); } 'fragment lives';
	lives_and { is $d->{uri}, 'http://host:7474'; } 'fragment removed';
};


subtest 'tls' => sub {
	plan tests => 9;
	my $ca_file = '8aA6EPsGYE7sbB7bLWiu.';  # doesn't exist
	lives_ok { $d = Neo4j::Driver->new('https://test/')->config(trust_ca => $ca_file); } 'create https with CA file';
	is $d->{tls_ca}, $ca_file, 'tls_ca';
	throws_ok { $d->session; } qr/\Q$ca_file\E/, 'https session fails with missing CA file';
	throws_ok {
		Neo4j::Driver->new('https://test/')->config(encrypted => 0)->session;
	} qr/\bHTTPS does not support unencrypted communication\b/i, 'no unencrypted https';
	lives_ok {
		$d = Neo4j::Driver->new('https://test/')->config(encrypted => 1);
		Neo4j_Test->transaction_unconnected($d);
	} 'encrypted https';
	ok $d->{tls}, 'tls';
	throws_ok {
		Neo4j::Driver->new('http://test/')->config(encrypted => 1)->session;
	} qr/\bHTTP does not support encrypted communication\b/i, 'no encrypted http';
	lives_and { is(Neo4j::Driver->new->config(tls => 4)->config('encrypted'), 4) } 'config tls';
	lives_and { is(Neo4j::Driver->new->config(tls_ca => $ca_file)->config('trust_ca'), $ca_file) } 'config tls_ca';
};


subtest 'auth' => sub {
	plan tests => 13;
	my $a = { scheme => 'basic', principal => 'user', credentials => 'pass' };
	lives_ok { $d = 0; $d = Neo4j::Driver->new->basic_auth(user => 'pass') } 'basic auth lives';
	lives_and { is_deeply $d->config('auth'), $a } 'basic auth';
	lives_ok { $d = 0; $d = Neo4j::Driver->new; $d->config(auth => \$a) } 'ref auth lives';
	lives_and { is_deeply ${$d->config('auth')}, $a } 'ref auth';
	lives_ok { $d = 0; $d = Neo4j::Driver->new->config(uri => 'http://foo:bar@test', auth => $a) } 'ambiguous auth lives';
	lives_and { is_deeply $d->{auth}, $a } 'ambiguous auth prefers auth over uri';
	# parsing from uri
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://user:pass@test:9999'); } 'auth in full uri lives';
	lives_and { is $d->{uri}, 'http://test:9999'; } 'auth in full uri';
	lives_and { is_deeply $d->{auth}, $a } 'auth from full uri';
	$a = { scheme => 'basic', principal => 'foo', credentials => '' };
	lives_ok { $d = 0; $d = Neo4j::Driver->new->config(uri => 'http://foo:@test') } 'uri no passwd auth lives';
	lives_and { is_deeply $d->{auth}, $a } 'uri no passwd auth';
	$a = { scheme => 'basic', principal => '', credentials => 'bar' };
	lives_ok { $d = 0; $d = Neo4j::Driver->new->config(uri => 'http://:bar@test') } 'uri no userid auth lives';
	lives_and { is_deeply $d->{auth}, $a } 'uri no userid auth';
};


subtest 'auth encoding unit' => sub {
	plan tests => 12;
	# The implied assumption here is that anything that *can* be decoded as UTF-8 probably *is* UTF-8.
	my $a = { scheme => 'basic', principal => "foo\x{100}foo", credentials => '' };
	lives_ok { $d = 0; $d = Neo4j::Driver->new("http://foo\x{c4}\x{80}foo\@test") } 'uri utf8 auth lives';
	lives_and { is_deeply $d->{auth}, $a } 'uri utf8 auth';
	lives_and { ok utf8::is_utf8 $d->{auth}->{principal} } 'uri utf8 auth flag';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://foo%C4%80foo@test') } 'uri encoded utf8 auth lives';
	lives_and { is_deeply $d->{auth}, $a } 'uri encoded utf8 auth';
	lives_and { ok utf8::is_utf8 $d->{auth}->{principal} } 'uri encoded utf8 auth flag';
	$a = { scheme => 'basic', principal => "bar\x{c4}\x{80}\x{ff}bar", credentials => '' };
	lives_ok { $d = 0; $d = Neo4j::Driver->new("http://bar\x{c4}\x{80}\x{ff}bar\@test") } 'uri latin1 auth lives';
	lives_and { is_deeply $d->{auth}, $a } 'uri latin1 auth';
	lives_and { ok ! utf8::is_utf8 $d->{auth}->{principal} } 'uri latin1 auth flag';
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http://bar%C4%80%ffbar@test') } 'uri encoded latin1 auth lives';
	lives_and { is_deeply $d->{auth}, $a } 'uri encoded latin1 auth';
	lives_and { ok ! utf8::is_utf8 $d->{auth}->{principal} } 'uri encoded latin1 auth flag';
};


subtest 'auth encoding integration' => sub {
	plan tests => 6;
	my ($m, $uri);
	$uri = 'http://utf8:%C4%80@test1:10001';
	lives_ok { $d = 0; $d = Neo4j::Driver->new($uri) } 'utf8 driver lives';
	lives_ok { $m = 0; $m = Neo4j::Driver::Net::HTTP::LWP->new($d) } 'utf8 net module lives';
	lives_and { is ''.$m->uri(), $uri } 'utf8 uri';
	$uri = 'http://latin1:%C4%80%FF@test2:10002';
	lives_ok { $d = 0; $d = Neo4j::Driver->new($uri) } 'latin1 driver lives';
	lives_ok { $m = 0; $m = Neo4j::Driver::Net::HTTP::LWP->new($d) } 'latin1 net module lives';
	lives_and { is ''.$m->uri(), $uri } 'latin1 uri';
};


subtest 'cypher params' => sub {
	plan tests => 21;
	my ($t, @q);
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 1';
	lives_ok { $d->config(cypher_params => v2); } 'set filter';
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
	throws_ok {
		$d->config(cypher_params => v3);
	} qr/\bUnimplemented cypher params filter\b/i, 'set filter unkown name';
	# no filter (for completeness)
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 3';
	lives_ok { $t = Neo4j_Test->transaction_unconnected($d); } 'new tx 3';
	@q = ('RETURN {a}', a => 17);
	lives_ok { $r = 0; $r = $t->_prepare(@q); } 'prepare unfiltered';
	is $r->{statement}, 'RETURN {a}', 'unfiltered';
	# verify that filter flag is automatically cleared for Neo4j 2
	my $config = {cypher_params => v2};
	my $d;
	lives_ok { $d = Neo4j::Driver->new($config)->plugin(Neo4j_Test::MockHTTP->new) } 'Neo4j 4: set filter mock';
	lives_and { ok !! $d->session(database => 'dummy')->{cypher_params_v2} } 'Neo4j 4: filter';
	my $mock_plugin_v2 = Neo4j_Test::MockHTTP->new(neo4j_version => '2.3.12');
	lives_ok { $d = Neo4j::Driver->new($config)->plugin($mock_plugin_v2) } 'Neo4j 2: set filter mock';
	lives_and { ok !  $d->session(database => 'dummy')->{cypher_params_v2} } 'Neo4j 2: no filter';
	$d = Neo4j::Driver->new('http:');
	my $mock_plugin_sim = Neo4j_Test::MockHTTP->new(neo4j_version => '0.0.0');
	lives_ok { $d = Neo4j::Driver->new($config)->plugin($mock_plugin_sim) } 'Sim: set filter mock';
	lives_and { ok !! $d->session(database => 'dummy')->{cypher_params_v2} } 'Sim (0.0.0): filter';
};


subtest 'session config' => sub {
	plan tests => 6;
	my $d = Neo4j::Driver->new('http:');
	lives_ok { $d->plugin( Neo4j_Test::MockHTTP->new(no_default_db => 1) ) } 'set mock';
	my %db = (database => 'foobar');
	lives_and { like $d->session( %db)->{net}{endpoints}{new_commit}, qr/\bfoobar\b/ } 'session hash';
	lives_and { like $d->session(\%db)->{net}{endpoints}{new_commit}, qr/\bfoobar\b/ } 'session hash ref';
	throws_ok { $d->session(  ) } qr/\bdefault database\b/i, 'session empty hash';
	throws_ok { $d->session({}) } qr/\bdefault database\b/i, 'session empty hash ref';
	throws_ok { $d->session('') } qr/\bOdd number of elements\b/i, 'session no ref';
};


done_testing;
