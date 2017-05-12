#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Noid;

$ENV{'SHELL'} = "/bin/sh";
my ($report, $erc);

sub short { my( $template )=@_;
	system("/bin/rm -rf ./NOID > /dev/null 2>&1 ");
	$report = Noid::dbcreate(".", "jak", $template, "short");
	! defined($report) and
		return(Noid::errmsg());
	open(IN, "<NOID/README") or
		die("can't open README: $!");
	local $/;
	$erc = <IN>;
	close(IN);
	return($erc);
	#return `./noid dbcreate $template short 2>&1`;
}

use Test::More tests => 17;

#BEGIN { use_ok('Noid') };

#########################

{	# Bind tests -- short

like short(".sdd"), qr/Size:\s*100\n/, '2-digit sequential';
my $noid = Noid::dbopen("NOID/noid.bdb", 0);
my $contact = "Fester Bestertester";
my $id;

$id = Noid::mint($noid, $contact, "");
$id = Noid::mint($noid, $contact, "");
is $id, "01", 'sequential mint verify';

like Noid::bind($noid, $contact, 1, "set", $id, "myelem", "myvalue"),
	qr/Status:  ok, 7/, 'simple bind';

like Noid::fetch($noid, 1, $id, "myelem"),
	qr/myelem: myvalue/, 'simple fetch';

like Noid::fetch($noid, 0, $id, "myelem"),
	qr/^myvalue$/, 'simple non-verbose (get) fetch';

Noid::dbclose($noid);
}

{	# Queue/hold tests -- short

like short(".sdd"), qr/Size:\s*100\n/, '2-digit sequential';
my $noid = Noid::dbopen("NOID/noid.bdb", 0);
my $contact = "Fester Bestertester";
my ($id, $status);

$id = Noid::mint($noid, $contact, "");
is $id, "00", 'mint first';

is Noid::hold($noid, $contact, "set", "01"), 1, 'hold next';

$id = Noid::mint($noid, $contact, "");
is $id, "02", 'mint next skips id held';

# Shouldn't have to release hold to queue it
like((Noid::queue($noid, $contact, "now", $id))[0],
	qr/id: $id/, 'queue previously held');

$id = Noid::mint($noid, $contact, "");
is $id, "02", 'mint next gets from queue';

$id = Noid::mint($noid, $contact, "");
is $id, "03", 'mint next back to normal';

Noid::dbclose($noid);
}

# XXX
# To do: set up a "long" minter and test the various things that
# it should reject, eg, queue a minted Id without first doing a
# "hold release Id"

{	# Validate tests -- short

like short("fk.redek"), qr/Size:\s*8410\n/, '4-digit random';
my $noid = Noid::dbopen("NOID/noid.bdb", 0);
my $contact = "Fester Bestertester";
my ($id, $status);

$id = Noid::mint($noid, $contact, "");
is $id, "fk491f", 'mint one';

is grep(/error: /, Noid::validate($noid, "-", "fk491f")),
	0, 'validate just minted';

is grep(/iderr: /, Noid::validate($noid, "-", "fk492f")),
	1, 'detect one digit off';

is grep(/iderr: /, Noid::validate($noid, "-", "fk419f")),
	1, 'detect transposition';

Noid::dbclose($noid);
}
