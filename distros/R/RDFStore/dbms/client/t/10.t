$|=1;
print "1..6\n";

use DBMS;


tie %a ,DBMS,'aah',&DBMS::XSMODE_RDWR,0 and print "ok\n" or die "$! 1";
untie %a;
tie %b ,DBMS,'bee',&DBMS::XSMODE_RDWR,0 and print "ok\n" or die "$! 2";
untie %b;

# Set to readonly - and we should see two fails
print STDERR "Two fails coming up\n";
tie %a ,DBMS,'aah',&DBMS::XSMODE_RDONLY,0 and print "ok\n" or die "$! 3";
tie %b ,DBMS,'bee',&DBMS::XSMODE_RDONLY,0 and print "ok\n" or die "$! 4";

$a{ key_in_a } = val_in_a;
$b{ key_in_b } = val_in_b;

print STDERR "No more fails here.\n";

untie %b and print "ok\n" or warn $!;
untie %a and print "ok\n" or warn $!;
 
