print "1..8\n";

use DBMS;


tie %a,DBMS,'zoink',&DBMS::XSMODE_CREAT,0 and print "ok\n"
	or die "could not connect $!";

%a=();
for $r ( 1 .. 10) {
	$a{ $r } = $r x (16*8);
	};

print "ok\n";

$|=1;
for $i (1..3) {
	untie %a;
	tie %a,DBMS,'zoink',&DBMS::XSMODE_CREAT,0 and print "ok\n"
		or die "could not connect $!";

	for $i (1..2) {
		for $r (1..10) {
			$c = $a{ $r };
			$c='';
			};
		};
	print "ok\n";
	};
%a=();
untie %a;
