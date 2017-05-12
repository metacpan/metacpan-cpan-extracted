print "1..4\n";

use DBMS;


for my $a (1..2) {

tie %a,DBMS,'biggie',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
%a=();
$last_a=$last='';
for $i ( 1 .. 100 ) {
	$a=  '.' x ( $i * 128 );

	$a{ $i } = $a
		or die "Storing failed: $!";

	die "Retrieval failed"
		if defined($a{ $last}) && ($a{ $last } ne $last_a) ;

	$last_a = $a;
	$last  = $i;
	};
%a=();
untie %a;

print "ok\n";
};
