use Test;
use MIME::Base64 qw(decode_base64);

my $enable_online_tests = 0;
my($host, $user, $pass, $complete);

$complete = 1;
if (defined(open(F, "<.config"))) {
	my $enabled = <F>;
	if ($enabled =~ /enabled/) {
		$enable_online_tests = 1;
		$host = <F> || { $complete = 0 };
		$user = <F> || { $complete = 0 };
		$pass = <F> || { $complete = 0 };
		$host =~ s/[\r\n]+$//g;
		$user =~ s/[\r\n]+$//g;
		$pass =~ s/[\r\n]+$//g;
		$pass = decode_base64($pass);
	}
	close(F);
}

my $ntests = ($enable_online_tests == 1 ? 19 : 7);
plan tests => $ntests;

# Test 1 = Create an object
eval {
	require Net::MirapointAdmin;
	return 1;
};
ok($@, '');
croak() if $@;		# Fail Hard

use Net::MirapointAdmin;	# If we get here, bring it in permanently

# Test 2 = try to create an object for an invalid Mirapoint host
#	using low level protocol
my $mp = new Net::MirapointAdmin('localhost');
ok(ref($mp), "Net::MirapointAdmin");

# Test 3 = we should not be connected - we are in trouble if we are
ok($mp->connected(), 0);

# Test 4 = attempt to connect - use the backdoor to return undef on
#	failure.  This should not work.
eval {
	return $mp->connect(1);
};
ok(!defined($@), '');

# Test 5 = check the failure code
ok($Net::MirapointAdmin::ERRSTR ne "");

# Test 6 = attempt to xmit something - it must return undef
ok(!defined($mp->xmit("COMMAND")));

# Test 7 = attempt to getbuf something - it must return undef
ok(!defined($mp->getbuf("COMMAND")));

goto END if ($enable_online_tests == 0);
		
# Test 8 = set up an object for connecting to the remote host
$mp = new Net::MirapointAdmin($host);
ok(ref($mp), "Net::MirapointAdmin");

# Test 9 = check to ensure we are not connected
ok($mp->connected(), 0);

# Test 10 = Attempt to connect
ok(defined($mp->connect(1)));

# Test 11 = Make sure we are connected now
ok($mp->connected(), 1);

# Test 12 = we should not be logged in
ok($mp->loggedin(), 0);

# Test 13 = there should be nothing in the ERRSTR
ok($Net::MirapointAdmin::ERRSTR, '');

# Test 14 = Call object xmit("tag LOGIN user pass") and ensure 
# we don't die
my $ret;
eval {
	$ret = $mp->xmit("tag LOGIN \"$user\" \"$pass\"");
};
ok($@, '');

# Test 15 = check byte counts on either side
my $bytes = 17 + length($user) + length($pass);
ok($ret == $bytes);

# Test 16 = Call getbuf 
eval {
	$ret = $mp->getbuf;
};
ok($@, '');
	
# Test 17 = return should be * tag
ok($ret =~ /^\* tag/);

# Test 18 = Call getbuf again
eval {
	$ret = $mp->getbuf
};
ok($@, '');

# Test 19 = return should tag OK
ok($ret =~ /^tag OK/);

END: 

# End-Of-Script
1;


