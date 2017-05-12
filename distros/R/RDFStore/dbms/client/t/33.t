$childs=6;

$|=1;
print "1..".(6+$childs*6)."\n";
$M=500;
$dt=time;
my $ttt = ($M*4+6+2) * $childs;

use DBMS;
for $cc ( 1..$childs ) {
	if (fork()==0) {
$|=1;
tie %a ,DBMS,'aah'.$cc.$$,&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
tie %b ,DBMS,'bee',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
$a{ key_in_a } = val_in_a;
$b{ key_in_b } = val_in_b;
untie %b;
untie %a;

tie %c ,DBMS,'cee',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
$c{ key_in_c } = val_in_c;
untie %c;

tie %a ,DBMS,'aah',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
tie %b ,DBMS,'bee'.$cc.$$,&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
$a{ key_in_a } = val_in_a;
$b{ key_in_b } = val_in_b;
untie %b;
untie %a;

tie %c ,DBMS,'cee',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
$c{ key_in_c } = val_in_c;
untie %c;
exit;
};
};

while(1) {
	last if wait == -1;
   print "ok\n";
	};

$dt = time - $dt;
#print "N=".$ttt." ".($ttt/$dt)." ok\n";
