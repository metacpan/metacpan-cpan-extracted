print "1..8\n";

use DBMS;


tie %a ,DBMS,'aah',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "$! 1";
untie %a;
tie %b ,DBMS,'bee',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "$! 2";
untie %b;

tie %a ,DBMS,'aah',&DBMS::XSMODE_RDONLY,0 and print "ok\n" or die "$! 3";
tie %b ,DBMS,'bee',&DBMS::XSMODE_RDONLY,0 and print "ok\n" or die "$! 4";
$p = $a{ key_in_a };
$p = $a{ key_in_b };

tie %a ,DBMS,'aah',&DBMS::XSMODE_RDWR,0 and print "ok\n" or die "$! 3";
tie %b ,DBMS,'bee',&DBMS::XSMODE_RDWR,0 and print "ok\n" or die "$! 4";
$a{ key_in_a } = val_in_a;
$b{ key_in_b } = val_in_b;

untie %b and print "ok\n" or warn $!;
untie %a and print "ok\n" or warn $!;
 
