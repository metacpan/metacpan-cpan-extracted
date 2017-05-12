# t/01_load.t; just to load Software::Packager by using it

$|++; 
print "1..1\n";
my($test) = 1;

# 1 load
use Software::Packager;
my($loaded) = 1;
$loaded ? print "ok $test\n" : print "not ok $test\n";
$test++;


