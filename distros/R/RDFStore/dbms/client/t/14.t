print "1..6\n";
use DBMS;


$|=1;
tie %a ,DBMS,'aah',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
tie %b ,DBMS,'bee',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
$a{ key_in_a } = val_in_a;
$b{ key_in_b } = val_in_b;
untie %b;
untie %a;

tie %c ,DBMS,'cee',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
$c{ key_in_c } = val_in_c;
untie %c;

tie %a ,DBMS,'aah',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
tie %b ,DBMS,'bee',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
$a{ key_in_a } = val_in_a;
$b{ key_in_b } = val_in_b;
untie %b;
untie %a;

tie %c ,DBMS,'cee',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
$c{ key_in_c } = val_in_c;
untie %c;
