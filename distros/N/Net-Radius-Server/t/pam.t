#!/usr/bin/perl

use Test::More tests => 48;

use IO::File;
use IO::Prompt;
use Net::Radius::Packet;
use Net::Radius::Dictionary;
use Net::Radius::Server::Base qw/:match :set/;

# Init the dictionary for our test run...
BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	User-Password		2	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
ATTRIBUTE	Reply-Message		18	string
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

use_ok('Net::Radius::Server::PAM');
diag("Using service 'login' for the remaining tests");

my $pam = Net::Radius::Server::PAM->new({ service => 'login' });
my $m_pam = $pam->fmatch();
my $s_pam = $pam->fset();
is(ref($m_pam), "CODE", "Match factory returns a coderef/sub");
is(ref($s_pam), "CODE", "Set factory returns a coderef/sub");

# Class hierarchy and contents
isa_ok($pam, 'Exporter');
isa_ok($pam, 'Class::Accessor');
isa_ok($pam, 'Net::Radius::Server');
isa_ok($pam, 'Net::Radius::Server::Set');
isa_ok($pam, 'Net::Radius::Server::Match');
isa_ok($pam, 'Net::Radius::Server::Set::Simple');
isa_ok($pam, 'Net::Radius::Server::PAM');

can_ok($pam, 'new');
can_ok($pam, 'log');
can_ok($pam, 'log_level');
can_ok($pam, 'fmatch');
can_ok($pam, 'result');
can_ok($pam, 'attr');		# Comes from ::Set::Simple
can_ok($pam, 'fset');
can_ok($pam, 'mk');		# Should croak() when called
can_ok($pam, '_set');
can_ok($pam, '_match');

like($pam->description, qr/Net::Radius::Server::PAM/, 
     "Description contains the class");
like($pam->description, qr/pam\.t/, "Description contains the filename");
like($pam->description, qr/:\d+\)$/, "Description contains the line");

# Create an incomplete Access-Request packet
my $d = new Net::Radius::Dictionary "dict.$$";
isa_ok($d, 'Net::Radius::Dictionary');
my $p = new Net::Radius::Packet $d;
isa_ok($p, 'Net::Radius::Packet');
$p->set_identifier(42);
$p->set_authenticator('1234567890abcdef');
$p->set_code("Access-Request");

my $hash = { dict => $d, secret => 'mysecret', request => $p };
is($m_pam->($hash), NRS_MATCH_FAIL, "Incomplete packet causes FAIL");

# Now we need to work with user-supplied input

sleep 1;
diag("\nFurther testing requires credentials to login to this box");
if ($ENV{NRS_INTERACTIVE} and prompt(q{Run this test? [y/n]: }, -yes))
{
    sleep 1;
    diag("\nWe need a username to test");
    my $login = getpwuid($<);
    my $user = prompt(qq{Username [$login]: }, -d => $login);

    sleep 1;
    diag("\nWe need the user's password to test authentication");
    my $pass = prompt(qq{Password for $user: }, -e => '*');

    # Create a working Access-Request packet and response
    $p->set_attr("User-Name" => $user);

    my $q = new Net::Radius::Packet $d;
    isa_ok($q, 'Net::Radius::Packet');
    $q->set_dict("dict.$$");
    
    # Now, test the correct password
    $p->set_password($pass, 'mysecret');

    $hash = { dict => $d, secret => 'mysecret', request => $p, 
	      response => $q };
    is($m_pam->($hash), NRS_MATCH_OK, "Correct password: Should match");

    # And the wrong password
    $p->set_password('bad' . $pass, 'mysecret');

    diag "A warning is ok here...";
    $hash = { dict => $d, secret => 'mysecret', request => $p, 
	      response => $q };
    is($m_pam->($hash), NRS_MATCH_FAIL, "Wrong password: Should fail");

    # Test the ->store_result attribute
    $pam->store_result('pass');
    $hash = { dict => $d, secret => 'mysecret', request => $p, 
	      response => $q };
    $p->set_password($pass, 'mysecret');
    is($m_pam->($hash), NRS_MATCH_OK, "Correct password: Should match");
    ok(exists $hash->{pass}, "Result properly stored");
    isa_ok($hash->{pass}, 'Authen::PAM');

    # When working with the set method alone, authentication should also
    # happen - Let's try it
    $pam->result(NRS_SET_RESPOND|NRS_SET_CONTINUE);
    $hash = { dict => $d, secret => 'mysecret', request => $p, 
	      response => $q };
    $p->set_password($pass, 'mysecret');
    is($s_pam->($hash), NRS_SET_RESPOND | NRS_SET_CONTINUE, 
       "Correct password in set: Should respond");
    ok(exists $hash->{pass}, "Result properly stored");
    isa_ok($hash->{pass}, 'Authen::PAM');

    # A set method that will fail
    $hash = { dict => $d, secret => 'mysecret', request => $p, 
	      response => $q };
    $p->set_password('bad' . $pass, 'mysecret');
    diag "A warning here is ok...";
    is($s_pam->($hash), NRS_SET_CONTINUE, 
       "Bad password in set: Should not respond");
    ok(! exists $hash->{pass}, "Result not stored");

    # Now work as a chain
    # When working with the set method alone, authentication should also
    # happen - Let's try it
    $hash = { dict => $d, secret => 'mysecret', request => $p, 
	      response => $q };
    $p->set_password($pass, 'mysecret');
    is($m_pam->($hash), NRS_MATCH_OK, "Correct password: Should match");
    ok(exists $hash->{pass}, "Result properly stored");
    isa_ok($hash->{pass}, 'Authen::PAM');

    # Add an environment var to be converted into a RADIUS attribute
    $hash->{pass}->pam_putenv('NAS-IP-Address=127.0.0.1');
    $hash->{pass}->pam_putenv('HOME=/dev/null');

    diag "Expect a few warnings below...";
    $pam->log_level(4);
    $pam->auto(1);
    $pam->attr([['Reply-Message' => 'Authenticated by PAM']]);

    is($s_pam->($hash), NRS_SET_RESPOND | NRS_SET_CONTINUE, 
       "Correct password in set: Should respond");
    ok(exists $hash->{pass}, "Result properly stored");
    isa_ok($hash->{pass}, 'Authen::PAM');
    is($hash->{response}->attr('NAS-IP-Address'), '127.0.0.1',
       "Conversion of env to RADIUS attributes");
    is($hash->{response}->attr('Reply-Message'), 'Authenticated by PAM',
       "Set RADIUS attributes via ->attr");
    is($hash->{response}->code, 'Access-Accept', 
       "Correct RADIUS response code");
    is($hash->{response}->identifier, $p->identifier, 
       "Correct RADIUS identifier");
    is($hash->{response}->authenticator, $p->authenticator, 
       "Correct RADIUS authenticator");
}
else
{
  SKIP: { skip "Interactive tests skipped or no credentials to test auth", 
	  22 };
}
