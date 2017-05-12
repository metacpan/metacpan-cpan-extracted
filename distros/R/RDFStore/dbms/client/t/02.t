print "1..4\n";

$|=1;
$N=shift || 500;
use DBMS;

no strict;

foreach my $ci (1 .. 4) {
	undef $DBMS::ERROR;
	my $a=tie %aap, 'DBMS','zappazoink',&DBMS::XSMODE_CREAT,0
		or die "E= $DBMS::ERROR $! $@ $?";

	for $i (1 .. $N) {
		$aap{ $i } = $i;
		};

	for $i (1 .. $N) {
		($c=$aap{ $i }) == $i || print "not ok\n";
		print "not ok\n" unless defined $c;
		};

	undef $a;
	untie %aap;
	print "ok\n";
	};
