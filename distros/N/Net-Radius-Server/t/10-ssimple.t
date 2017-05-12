use IO::File;
use Test::More tests => 40;

use Net::Radius::Packet;
use Net::Radius::Dictionary;
use Net::Radius::Server::Base qw/:set/;

# Init the dictionary for our test run...

BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	User-Password		2	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
ATTRIBUTE       Reply-Message           18      string
VENDOR		Cisco			9
VENDORATTR      9       cisco-avpair    1       string
EOF

    close $fh;
};

END { unlink 'dict.' . $$; }

use_ok('Net::Radius::Server::Set::Simple');

# Create an empty/trivial matcher
my $m = Net::Radius::Server::Set::Simple->new({});

# Class hierarchy and contents
isa_ok($m, 'Exporter');
isa_ok($m, 'Class::Accessor');
isa_ok($m, 'Net::Radius::Server');
isa_ok($m, 'Net::Radius::Server::Set');
isa_ok($m, 'Net::Radius::Server::Set::Simple');

can_ok($m, 'new');
can_ok($m, 'log');
can_ok($m, 'log_level');
can_ok($m, 'mk');
can_ok($m, '_set');
can_ok($m, 'result');
can_ok($m, 'auto');
can_ok($m, 'attr');
can_ok($m, 'code');
can_ok($m, 'vsattr');
can_ok($m, 'description');
like($m->description, qr/Net::Radius::Server::Set::Simple/, 
     "Description contains the class");
like($m->description, qr/10-ssimple.t/, "Description contains the filename");
like($m->description, qr/:\d+\)$/, "Description contains the line");

# Now test the factory
my $method = $m->mk();
is(ref($method), "CODE", "Factory returns a coderef/sub");

# Invocation with trivial matches
is($method->(), NRS_SET_CONTINUE, "Default return");

# Build a request/reply pair and test it is ok
my $req = new Net::Radius::Packet;
my $rep = new Net::Radius::Packet;
my $dic = new Net::Radius::Dictionary "dict.$$";

isa_ok($req, 'Net::Radius::Packet');
isa_ok($rep, 'Net::Radius::Packet');
isa_ok($dic, 'Net::Radius::Dictionary');

$req->set_dict($dic);
$rep->set_dict($dic);
$req->set_code("Access-Request");
$rep->set_code("Access-Reject");
$req->set_identifier('42');
$req->set_authenticator('So long and thanks for all the fish');
$req->set_attr("User-Name" => 'FOO@MY.DOMAIN');
$req->set_attr("NAS-IP-Address" => "127.0.0.1");

# Fake the arguments from a running framework
my $args = { request => $req, response => $rep, 
	     peer_addr => '10.10.10.10' };

# Verify the return value again
is($method->($args), NRS_SET_CONTINUE, "Default return with args");
$m->code('Access-Accept');
$m->result(NRS_SET_CONTINUE | NRS_SET_RESPOND);
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, setting the packet code");
is($rep->code, 'Access-Accept', "Correct response code");

$m->attr([[ 'Reply-Message' => 'Hello' ]]);
$m->vsattr([[ Cisco => 'cisco-avpair' => 'hello=world' ]]);
$m->auto(1);
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, setting the packet code");
is($rep->code, 'Access-Accept', "Correct response code");
is($rep->attr('Reply-Message'), 'Hello', 'Attribute value');
ok($rep->vsattr('Cisco', 'cisco-avpair'), "VSA is present");
is($rep->vsattr('Cisco', 'cisco-avpair')->[0], 'hello=world', 
   'VSAttribute value');
is(@{$rep->vsattr('Cisco', 'cisco-avpair')}, 1, 'Number of VSAs');
is($rep->identifier, $req->identifier, 'Id auto-copied');
is($rep->authenticator, $req->authenticator, 'Auth auto-copied');

can_ok($m, 'description');
like($m->description, qr/Net::Radius::Server::Set::Simple/, 
     "Description contains the class");
like($m->description, qr/10-ssimple.t/, "Description contains the filename");
like($m->description, qr/:\d+\)$/, "Description contains the line");
