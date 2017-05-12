print "1..3\n";

use No::PersonNr qw(personnr_ok er_mann er_kvinne fodt_dato);

$testno = 1;

# should have many more tests

for ('160964 44102',
     '16096444102',
     '16-09-64 44102',
    ) {
   print "$_\n";
   print "not " unless personnr_ok($_);
   print "ok $testno\n";
   $testno++;

   print "Mann\n" if er_mann($_);
   print "Kvinne\n" if er_kvinne($_);

   print fodt_dato($_), "\n";
}
