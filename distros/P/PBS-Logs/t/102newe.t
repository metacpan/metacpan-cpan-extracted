use Test::More tests => 6;
#use Test::More "no_plan";

use PBS::Logs::Event;

my $pl;
eval {
	$pl = new PBS::Logs::Event('XXX.20050304');
};
like($@,qr/PBS::Logs: new - can not open 'XXX.20050304'/,	"no log file");
ok(!defined $pl, 'not defined instance');

my %a = (1 .. 4 );
eval {
	$pl = new PBS::Logs::Event(\%a);
};
like($@,qr/PBS::Logs: new - must pass either filename, array reference, or filehandle glob ... not HASH/,	"Wrong type of reference");
ok(!defined $pl, 'not defined instance');

my $a = 1;
eval {
	$pl = new PBS::Logs::Event(\$a);
};
like($@,qr/PBS::Logs: new - must pass either filename, array reference, or filehandle glob ... not SCALAR/,	"Wrong type of reference");
ok(!defined $pl, 'not defined instance');

