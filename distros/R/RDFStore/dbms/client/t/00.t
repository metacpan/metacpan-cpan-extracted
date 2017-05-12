print "1..3\n";
use DBMS;


# Check if h2ph on ../dbms/include/dbms.h gerunned is..
#


tie %a ,DBMS,'aah',&DBMS::XSMODE_CREAT,0 and print "ok\n" or die "could not connect $!";
$a{'key_in_a'} = 'val_in_a';
print (($a{ "key_in_a" } eq "val_in_a") ? "ok\n" : "not ok\n");
untie %a;
print "ok\n";
