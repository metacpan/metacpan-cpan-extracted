print "1..100\n";

$|=1;
$N=shift || 150;
use DBMS;

no strict;
undef $DBMS::ERROR;

my $a=tie %aap, 'DBMS','zappazoink',&DBMS::XSMODE_CREAT,0
	or die "E= $DBMS::ERROR $! $@ $?";

foreach my $ci (1 .. 100) {

	for $i (1 .. $N) {
		$aap{ $i } = $i;
		};

	for $i (1 .. $N) {
		($c=$aap{ $i }) == $i || print "not ok\n";
		print "not ok\n" unless defined $c;
		};
print "ok\n";
	};

undef $a;
untie %aap;
