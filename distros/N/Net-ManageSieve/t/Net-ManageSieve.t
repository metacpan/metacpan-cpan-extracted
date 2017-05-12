use strict;
use warnings FATAL => 'all';

use constant dataf => 'managesieve-test-account';

use Carp;
use Test::More;
plan tests => 18;
use_ok('Net::ManageSieve');

unless(-r dataf) {
	SKIP: {
		skip "Install host data file " . dataf . " as described in README", 17;
	}
	exit 0;
}


my %cfg = (
);

if(open(LOGINDATA, '<', dataf)) {
	while(<LOGINDATA>) {
		chomp;
		next if /^\s*#/s;	# comment
		next unless s/^\s*(\S+)\s*=\s*//;
		my $opt = $1;
		s/\s+$//;
		if(/^"/s && /"$/s) {	# unquote
			$_ = substr($_, 1, length($_) - 2);
		}
		if($opt =~ /^(?:host|port|debug|timeout)$/) {
			$opt = ucfirst(lc($opt));
		}
		/^(.*)$/s;	# untaint
		$cfg{$opt} = $1;
	}
	close LOGINDATA;
}

croak "Define a host in file " . dataf . " to get host and login data from"
 unless $cfg{Host};

my $srv = Net::ManageSieve->new(%cfg);
ok($srv, "connect to server " . $cfg{Host} . ":" . $cfg{Port});

croak "Need a server connection" unless $srv;

my $cap = $srv->capabilities;

unless(scalar keys %$cap) {
	fail("No capabilities returned from server");
} else {
	my $err = "";
	$err .= ", SIEVE" unless $cap->{sieve};
	$err .= ", IMPLEMENTATION" unless $cap->{implementation};
	if($err) {
		fail("Missing required capabilities: " . substr($err, 2));
	} else {
		pass("Required capabilities found");
	}
}

SKIP: {
	skip "TLS already handled by new()", 2 if $srv->encrypted();
	skip "TLS disabled in config file", 2
	 if $cfg{tls} && $cfg{tls} =~ /^(?:disabled?|skip)$/i;
	skip "No STARTTLS available from server", 2 unless $cap->{starttls};

	ok($srv->starttls(), "Test STARTTLS");
	ok($srv->get_cipher(), "Test get_cipher");
}

SKIP: {
	skip "No user specified in file " . dataf, 1
	  unless $cfg{user} ||= $cfg{username};

	ok($srv->auth($cfg{user}, $cfg{password}), "TEST Authentificate");
}

ok($srv->havespace("TESTSCRIPT", 1), "TEST HaveSpace");

my $scripts = $srv->listscripts();
ok($scripts, "TEST ListScripts");
my $testScriptName = 'tstScript';
if($scripts) {
	my $i = 0;
	++$i while grep { $_ eq $testScriptName . $i } @$scripts;
	$testScriptName .= $i;
}
my $testScript = "# Net::ManageSieve TEST SCRIPT\n";
ok($srv->putscript($testScriptName, $testScript), "TEST PutScript");
my $script = $srv->getscript($testScriptName);
if($script) {
	is($script, $testScript, "TEST (re)GetScript");
} else {
	fail("(re)GetScript");
}
my $s;
if($s = $srv->listscripts()) {
	if(grep { $testScriptName eq $_ } @$s) {
		pass("Script uploaded onto server");
	} else {
		fail("Scrip NOT on server");
		$s = undef;
	}
} else {
	fail("Could not list scripts to verify it is there");
}
SKIP: {
	skip "Skip SetActive as test script is not on server", 4
	 unless $s;

	ok($srv->setactive($testScriptName), "TEST SetActive");
	if($s = $srv->listscripts()) {
		my $actScript = pop(@$s);
		is($actScript, $testScriptName, "Is active script the test script");
	} else {
		fail("Could not list scripts to verify SetActive");
	}
	# Deactive any script
	ok($srv->setactive(""), "TEST UnActive any script");
	if($s = $srv->listscripts()) {
		my $actScript = pop(@$s);
		is($actScript, '', "Is active script empty");
	} else {
		fail("Could not list scripts to verify UnSetActive");
	}

	# Reset to old state
	if($scripts) {
		my $oldScript = pop(@$scripts);
		$srv->setactive($oldScript) if $oldScript;
	}
}

ok($srv->deletescript($testScriptName), "TEST DeleteScript");

# Invalid Name
if(my $o = $srv->putscript($testScriptName."\n", $testScript)) {
	# Er, shouldn't
	fail("Uploading script with invalid name not blocked");
	$srv->deletescript($testScriptName."\n");
} else {
	pass("Uploading script with invalid name block succeeded");
}

ok($srv->logout(), "TEST Logout");
