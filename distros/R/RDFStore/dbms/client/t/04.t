print "1..5\n";

$|=1;
$N=shift || 500;
use DBMS;

no strict;

foreach $db (1 .. 5) {
my $a=tie %aap, 'DBMS','zappazoink'.$db,&DBMS::XSMODE_CREAT,0
	or print "not ok\n";

for $i (1..$N) {
	$aap{ $i } = $i;
	};

for $i (1..$N) {
	($c=$aap{ $i }) == $i || print "not ok\n";
	print "not ok\n" unless defined $c;
	};

undef $a;
untie %aap;

print "ok\n";
}
