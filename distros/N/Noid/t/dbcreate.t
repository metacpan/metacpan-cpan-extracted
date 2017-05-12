# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl dbcreate.t'

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

use Test::More tests => 11;

#BEGIN { use_ok('Noid') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{	# Size tests

like short(".sd"), qr/Size:\s*10\n/, 'single digit sequential template';

like short(".sdd"), qr/Size:\s*100\n/, '2-digit sequential template';

like short(".zded"), qr/Size:\s*unlimited\n/, '3-digit unbounded sequential';

like short("fr.reedde"), qr/Size:\s*2438900\n/, '6-digit random template';

}

{	# Some template error tests

like short("ab.rddd"), qr/Size:\s*1000\n/, 'prefix vowels ok in general';

like short("ab.rdxdk"), qr/parse_template: a mask may contain only the letters/,
	'bad mask char';

like short("ab.rdddk"), qr/a mask may contain only characters from/,
	'prefix vowels not ok with check char';

}

{	# Set up a generator that we will test

like short("8r9.sdd"), qr/Size:\s*100\n/, '2-digit sequential';
my $noid = Noid::dbopen("NOID/noid.bdb", 0);
my $contact = "Fester Bestertester";
my $id;

my $n = 1;
$id = Noid::mint($noid, $contact, "")		while ($n--);
is $id, "8r900", 'sequential mint test first';

$n = 99;
$id = Noid::mint($noid, $contact, "")		while ($n--);
is $id, "8r999", 'sequential mint test last';

$n = 1;
$id = Noid::mint($noid, $contact, "")		while ($n--);
is $id, "8r900", 'sequential mint test wrap to first';

Noid::dbclose($noid);
}
