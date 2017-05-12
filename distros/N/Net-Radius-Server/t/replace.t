use IO::File;
use Test::More tests => 61;

use NetAddr::IP;
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

use_ok('Net::Radius::Server::Set::Replace');

# Create an empty/trivial replacer
my $m = Net::Radius::Server::Set::Replace->new({});

# Class hierarchy and contents
isa_ok($m, 'Exporter');
isa_ok($m, 'Class::Accessor');
isa_ok($m, 'Net::Radius::Server');
isa_ok($m, 'Net::Radius::Server::Set');
isa_ok($m, 'Net::Radius::Server::Set::Replace');

# Now test the factory
my $method = $m->mk();
is(ref($method), "CODE", "Factory returns a coderef/sub");

# Invocation with trivial matches
is($method->(), NRS_SET_CONTINUE, "Default return");

can_ok($m, 'new');
can_ok($m, 'log');
can_ok($m, 'log_level');
can_ok($m, 'mk');
can_ok($m, '_set');
can_ok($m, 'attr');
can_ok($m, 'vsattr');
can_ok($m, 'result');
can_ok($m, 'description');
like($m->description, qr/Net::Radius::Server::Set::Replace/, 
     "Description contains the class");
like($m->description, qr/replace.t/, "Description contains the filename");
like($m->description, qr/:\d+\)$/, "Description contains the line");

sub _new_args
{
    my $req = new Net::Radius::Packet;
    my $rep = new Net::Radius::Packet;
    my $dic = new Net::Radius::Dictionary "dict.$$";
    
    $req->set_dict($dic);
    $rep->set_dict($dic);
    $req->set_code("Access-Request");
    $rep->set_code("Access-Reject");
    $req->set_identifier('42');
    $req->set_authenticator('So long and thanks for all the fish');
    $req->set_attr("User-Name" => 'FOO@MY.DOMAIN');
    $req->set_attr("NAS-IP-Address" => "127.0.0.1");

    return { request => $req, response => $rep, 
	     peer_addr => '10.10.10.10' };
}

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
my $args = _new_args;

# Verify the return value again
is($method->($args), NRS_SET_CONTINUE, "Default return with args");
$m->result(NRS_SET_CONTINUE | NRS_SET_RESPOND);
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, with another result");

$m->attr([ 'Reply-Message', 'Welcome' => 'Hello' ]);
$m->vsattr([ 'Cisco', 'cisco-avpair', 'Bienvenido' => 'hello=world' ]);
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, setting the packet code");
ok(!$args->{response}->attr('Reply-Message'), 
   'No attribute replacement (scalar)');
ok(!$args->{response}->vsattr('Cisco', 'cisco-avpair'), 
   "No VSA is present (scalar)");

$m->attr([ 'Reply-Message', qr/Welcome/ => 'Hello' ]);
$m->vsattr([ 'Cisco', 'cisco-avpair', qr/Bienvenido/ => 'hello=world' ]);
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, setting the packet code");
ok(!$args->{response}->attr('Reply-Message'), 'No attribute replacement (re)');
ok(!$args->{response}->vsattr('Cisco', 'cisco-avpair'), 
   "No VSA is present (re)");

$m->attr([ 'Reply-Message', NetAddr::IP->new('loopback') => 'Hello' ]);
$m->vsattr([ 'Cisco', 'cisco-avpair',  NetAddr::IP->new('loopback') 
	     => 'hello=world' ]);
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, setting the packet code");
ok(!$args->{response}->attr('Reply-Message'), 
   'No attribute replacement (nip)');
ok(!$args->{response}->vsattr('Cisco', 'cisco-avpair'), 
   "No VSA is present (nip)");

$args->{response}->set_attr('Reply-Message', '127.0.0.10');
$args->{response}->set_vsattr('Cisco', 'cisco-avpair', '127.0.0.50');
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, setting the packet code");
ok($args->{response}->attr('Reply-Message'), 'Attribute replacement (nip)');
ok($args->{response}->vsattr('Cisco', 'cisco-avpair'), "VSA is present (nip)");
is($args->{response}->attr('Reply-Message'), 'Hello', 'Replaced attr value');
is(@{$args->{response}->vsattr('Cisco', 'cisco-avpair')}, 1, 'Number of VSAs');
is($args->{response}->vsattr('Cisco', 'cisco-avpair')->[0], 'hello=world', 
   'Replaced vsa value');

# Add two sets of VSAs and verify that only one is actually changed

$args = _new_args;
$args->{response}->set_attr('Reply-Message', '127.0.0.10');
$args->{response}->set_vsattr('Cisco', 'cisco-avpair', '127.0.0.50');
$args->{response}->set_vsattr('Cisco', 'cisco-avpair', 'foo=bar');
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, setting the packet code");
ok($args->{response}->attr('Reply-Message'), 'Attribute replacement (nip)');
ok($args->{response}->vsattr('Cisco', 'cisco-avpair'), "VSA is present (nip)");
is($args->{response}->attr('Reply-Message'), 'Hello', 'Replaced attr value');
is(@{$args->{response}->vsattr('Cisco', 'cisco-avpair')}, 2, 'Number of VSAs');
is($args->{response}->vsattr('Cisco', 'cisco-avpair')->[0], 'hello=world', 
   'Replaced vsa value');
is($args->{response}->vsattr('Cisco', 'cisco-avpair')->[1], 'foo=bar', 
   'Original vsa value');

# Verify positive tests with an exact match
$args = _new_args;
$m->attr([ 'Reply-Message', 'Welcome' => 'Hello' ]);
$m->vsattr([ 'Cisco', 'cisco-avpair', 'Bienvenido' => 'hello=world' ]);
$args->{response}->set_attr('Reply-Message', 'Welcome');
$args->{response}->set_vsattr('Cisco', 'cisco-avpair', 'foo=bar');
$args->{response}->set_vsattr('Cisco', 'cisco-avpair', 'Bienvenido');
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, setting the packet code");
ok($args->{response}->attr('Reply-Message'), 'Attribute replacement (nip)');
ok($args->{response}->vsattr('Cisco', 'cisco-avpair'), "VSA is present (nip)");
is($args->{response}->attr('Reply-Message'), 'Hello', 'Replaced attr value');
is(@{$args->{response}->vsattr('Cisco', 'cisco-avpair')}, 2, 'Number of VSAs');
is($args->{response}->vsattr('Cisco', 'cisco-avpair')->[1], 'hello=world', 
   'Replaced vsa value');
is($args->{response}->vsattr('Cisco', 'cisco-avpair')->[0], 'foo=bar', 
   'Original vsa value');

# Verify again, with regexp match
$args = _new_args;
$m->attr([ 'Reply-Message', qr'Welcome' => 'Hello' ]);
$m->vsattr([ 'Cisco', 'cisco-avpair', qr'Bienvenido' => 'hello=world' ]);
$args->{response}->set_attr('Reply-Message', 'Welcome');
$args->{response}->set_vsattr('Cisco', 'cisco-avpair', 'foo=bar');
$args->{response}->set_vsattr('Cisco', 'cisco-avpair', 'Bienvenido');
is($method->($args), NRS_SET_CONTINUE | NRS_SET_RESPOND, 
   "Execute, setting the packet code");
ok($args->{response}->attr('Reply-Message'), 'Attribute replacement (nip)');
ok($args->{response}->vsattr('Cisco', 'cisco-avpair'), "VSA is present (nip)");
is($args->{response}->attr('Reply-Message'), 'Hello', 'Replaced attr value');
is(@{$args->{response}->vsattr('Cisco', 'cisco-avpair')}, 2, 'Number of VSAs');
is($args->{response}->vsattr('Cisco', 'cisco-avpair')->[1], 'hello=world', 
   'Replaced vsa value');
is($args->{response}->vsattr('Cisco', 'cisco-avpair')->[0], 'foo=bar', 
   'Original vsa value');
