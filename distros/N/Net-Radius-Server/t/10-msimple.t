use IO::File;
use Test::More tests => 48;

use NetAddr::IP;
use Net::Radius::Packet;
use Net::Radius::Dictionary;
use Net::Radius::Server::Base qw/:match/;

# Init the dictionary for our test run...
BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	User-Password		2	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
EOF

    close $fh;
};

END { unlink 'dict.' . $$; }

use_ok('Net::Radius::Server::Match::Simple');

# Create an empty/trivial matcher
my $m = Net::Radius::Server::Match::Simple->new({ log_level => -1 });

# Class hierarchy and contents
isa_ok($m, 'Exporter');
isa_ok($m, 'Class::Accessor');
isa_ok($m, 'Net::Radius::Server');
isa_ok($m, 'Net::Radius::Server::Match');
isa_ok($m, 'Net::Radius::Server::Match::Simple');

can_ok($m, 'new');
can_ok($m, 'mk');
can_ok($m, 'log');
can_ok($m, 'log_level');
can_ok($m, '_match');
can_ok($m, 'addr');
can_ok($m, 'attr');
can_ok($m, 'code');
can_ok($m, 'peer_addr');
can_ok($m, 'peer_port');
can_ok($m, 'port');

can_ok($m, 'description');
like($m->description, qr/Net::Radius::Server::Match::Simple/, 
     "Description contains the class");
like($m->description, qr/10-msimple.t/, "Description contains the filename");
like($m->description, qr/:\d+\)$/, "Description contains the line");

# Now test the factory
my $method = $m->mk();
is(ref($method), "CODE", "Factory returns a coderef/sub");

# Invocation with trivial matches
is($method->(), NRS_MATCH_OK, "No conditions: Should match");

# Build a request and test it is ok
my $p = new Net::Radius::Packet;
my $d = new Net::Radius::Dictionary "dict.$$";
isa_ok($p, 'Net::Radius::Packet');
isa_ok($d, 'Net::Radius::Dictionary');
$p->set_dict($d);
$p->set_code("Access-Request");
$p->set_attr("User-Name" => 'FOO@MY.DOMAIN');
$p->set_attr("NAS-IP-Address" => "127.0.0.1");

# Now test the invocation passing some parameters
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK, 
   "Request but no conditions: Should match");

# Add the first condition - Match against an unexistant attribute
$m->attr([ 'Foo-Bar' => 'foomatic' ]);

is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL, 
   "Request and funny condition: Should fail");

# Good attribute condition. The code won't match
$m->attr([ 'User-Name' => qr/(?i)\@my\.domain\.?$/ ]);
$m->code(qr/(?i)^access-accept$/);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL, 
   "Bad packet code");

# Now use a good packet code
$m->code(qr/(?i)^access-request$/);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "Good packet code");

# Now try alternative ways to do both
$m->code('Access-Accept');
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL, 
   "Bad packet code (string)");
$m->code('Access-Request');
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK, 
   "Ok packet code (string)");

$m->attr([ 'User-Name' => qr/(?i)\@my\.domain\.?$/,
	   'NAS-IP-Address' => '127.0.0.2',
	   ]);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL,
   "Bad NAS-IP-Address");

$m->attr([ 'User-Name' => qr/(?i)\@my\.domain\.?$/,
	   'NAS-IP-Address' => '127.0.0.1',
	   ]);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "Good NAS-IP-Address");

# Test NetAddr::IP matching...
$m->attr(['NAS-IP-Address' => NetAddr::IP->new('127/8') ]);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "NAS-IP-Address verified using NetAddr::IP");

# Test matching of the peer address
$m->peer_addr('10.10.10.10');
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "Peer address, using exact match");

is($method->( { peer_addr => '10.10.10.11', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL,
   "Peer address, using exact match (fail)");

$m->peer_addr(qr/^(?:10\.){3}10$/);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "Peer address, using regexp match");

is($method->( { peer_addr => '10.10.10.11', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL,
   "Peer address, using regexp match (fail)");

$m->peer_addr(NetAddr::IP->new('10.10.10/24'));
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "Peer address, using NetAddr::IP match");

is($method->( { peer_addr => '10.10.11.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL,
   "Peer address, using NetAddr::IP match (fail)");

$m->peer_port(qr/^9+$/);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "Peer port, using regexp match");

$m->peer_port(qr/^9+8$/);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL,
   "Peer port, using regexp match (fail)");

$m->peer_port(8888);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL,
   "Peer port, using exact match (fail)");

$m->peer_port(9999);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "Peer port, using exact match");

$m->port(1812);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "Local port, using exact match");

$m->port(1813);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL,
   "Local port, using exact match (fail)");

$m->port(qr/^1812$/);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_OK,
   "Local port, using regexp match");

$m->port(qr/^1813$/);
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		request => $p } ), NRS_MATCH_FAIL,
   "Local port, using regexp match (fail)");

