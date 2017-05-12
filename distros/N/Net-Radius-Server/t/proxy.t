#!/usr/bin/perl

use Test::More tests => 31;

use IO::File;
use IO::Prompt;
use Net::Radius::Packet;
use Net::Radius::Dictionary;
use Net::Radius::Server::Base qw/:set/;

# Init the dictionary for our test run...
BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	User-Password		2	string
EOF

    close $fh;
};

END { unlink 'dict.' . $$; }

unless ($ENV{NRS_INTERACTIVE})
{
    diag(<<EOF);


This test includes an interactive component. To enable it,
set the environment variable \$NRS_INTERACTIVE to some true
value.


EOF
}

use_ok('Net::Radius::Server::Set::Proxy');

my $proxy = Net::Radius::Server::Set::Proxy->new({});
my $m_proxy = $proxy->mk();
is(ref($m_proxy), "CODE", "Factory returns a coderef/sub");

# Class hierarchy and contents
isa_ok($proxy, 'Exporter');
isa_ok($proxy, 'Class::Accessor');
isa_ok($proxy, 'Net::Radius::Server');
isa_ok($proxy, 'Net::Radius::Server::Set');
isa_ok($proxy, 'Net::Radius::Server::Set::Proxy');

can_ok($proxy, 'new');
can_ok($proxy, 'log');
can_ok($proxy, 'log_level');
can_ok($proxy, 'mk');
can_ok($proxy, '_set');
can_ok($proxy, 'set_server');
can_ok($proxy, 'result');
can_ok($proxy, 'server');
can_ok($proxy, 'port');
can_ok($proxy, 'secret');
can_ok($proxy, 'dictionary');
can_ok($proxy, 'timeout');
can_ok($proxy, 'tries');
can_ok($proxy, 'description');
like($proxy->description, qr/Net::Radius::Server::Set::Proxy/, 
     "Description contains the class");
like($proxy->description, qr/proxy\.t/, "Description contains the filename");
like($proxy->description, qr/:\d+\)$/, "Description contains the line");


# XXX - sleep seems to be the only semi-reliable way to sync the prompts
sleep 1;
diag(qq{
The following tests require access to a live RADIUS server.
});

if ($ENV{NRS_INTERACTIVE} and 
    prompt(q{Do you want to run this test? [y/n]: }, -yes))
{
    diag("\nPlease tell me the IP address of your real RADIUS server");
    my $server = prompt("IP address of real RADIUS server: ");
    my $secret = prompt("Please tell me the RADIUS shared secret to use: ",
			-echo => '*');
    my $port 
	= prompt("Please tell me the port where the RADIUS server listens: ");

    chomp($server);
    chomp($secret);
    chomp($port);

    diag(q{

Attempting a request that should fail

});

    # Build a request/reply pair and test it is ok
    my $req = new Net::Radius::Packet;
    my $rep = new Net::Radius::Packet;
    my $dic = Net::Radius::Dictionary->new("dict.$$");

    isa_ok($req, 'Net::Radius::Packet');
    isa_ok($rep, 'Net::Radius::Packet');
    isa_ok($dic, 'Net::Radius::Dictionary');

    $req->set_dict($dic);
    $rep->set_dict($dic);
    $req->set_code("Access-Request");
    $rep->set_code("Access-Reject");
    $req->set_identifier('42');
    $req->set_authenticator(substr('So long and thanks for all the fish', 
				   0, 16));
    $req->set_attr("User-Name" => 'FOO@MY.DOMAIN');
    $req->set_password('I_HOPE_THIS_IS_NOT_YOUR_PASSWORD', 
		       "secret-$$");

    $proxy->dictionary("dict.$$");
    $proxy->secret($secret);
    $proxy->server($server);
    $proxy->port($port);
    $proxy->timeout(2);
    $proxy->tries(3);

    my $r = $m_proxy->({ packet => $req->pack, request => $req, 
			 response => $rep, secret => "secret-$$" });

    is($r, NRS_SET_CONTINUE, "Failed RADIUS response ($r)");

    is($rep->code, 'Access-Reject', "Correct response from wrong packet");

    sleep 1;
    diag q{

Please review your RADIUS server detail file or logs. I tried to 
authenticate the user 'FOO@MY.DOMAIN' with no password. 

If you see evidence that we sent the request, then you can consider
this test as succesful. Make sure you check your network permissions
before declaring a failure.

};
  
    prompt ("Press ENTER to continue: ");

    sleep 1;
    diag q{

Now, a valid authentication will be attempted.

};
  
    my $user = prompt("Please input a username for this RADIUS server: ");
    my $pass = prompt("Please provide a valid password for this user: ",
		      -echo => '*');

    chomp($user);
    chomp($pass);
    
    sleep 1;
    diag(q{

Attempting a request that should succeed

});

    $req->set_attr("User-Name" => $user);
    $req->set_password($pass, "secret-$$");
    $proxy->result(NRS_SET_RESPOND);
    is($m_proxy->({ packet => $req->pack, request => $req, 
		    response => $rep, secret => "secret-$$" }), 
       NRS_SET_RESPOND, "Correct RADIUS response");
    
    like($rep->code, qr/Access/, "Correct response for good credentials");
}
else
{
  SKIP: { skip 'No interactive tests or no live RADIUS server supplied', 7 };
}
