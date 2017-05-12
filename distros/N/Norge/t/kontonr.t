print "1..55\n";

use No::KontoNr qw(kontonr_ok kredittkortnr_ok mod_10 kontonr_f nok_f);

$testno = 1;

print "Noen gyldige bankkontonummer...\n";
for ('52050603512',
     '5205 06 03512',  # space skal være lov
     '5205.06.03512',  #
     '05711675827',
     '65040503190',
     '08065989728',
     '90010705990',
     '08063873080',
     '05409926853',
     '52050681602',
     '08135205851',
     '20850500186',
     '08015444674',
     '82000148888',
     '08260122720',
     '82000127287',

     # noen postgiro nr
     '10 50905',
     '1500206',
     '1694801',
     ) {
    my $k = $_;
    $k =~ s/\D//g;
    print "not " unless kontonr_ok($_) eq $k;
    print "ok $testno\n";
    $testno++;
}

print "Noen ugyldige bankkontonummer...\n";
for ('520506035123',  # for langt
     '520506035',     # for kort
     '5205-06-03512',
     undef,
     '52050603513',
     '52050603514',
     '52050603515',
     '52050603516',
     '52050603517',
     '52050603518',
     '52050603519',
     '52050603510',
     '52050603511',
     ) {
    print "not " if kontonr_ok($_);
    print "ok $testno\n";
    $testno++;
}

print "Kredittkortnr...\n";
print "not " unless kredittkortnr_ok("5413 0666 9455 0196");
print "ok $testno\n";  $testno++;

print "Modulus 10 sjekk...\n";
for (['1'          => 8],
     ['12'         => 5],
     ['123'        => 0],
     ['1234'       => 4],
     ['12345'      => 5],
     ['1234567'    => 4],
     ['12345678'   => 2],
     ['123456789'  => 7],
     ['1234567890' => 3],
     ['6'          => 7],
     ['66'         => 1],
     ['666'        => 8],
     ['6666'       => 2],
     ['66666'      => 9],
     ) {
    my($siffer, $forventet) = @$_;
    my $m10 = mod_10($siffer);
    print "mod_10($siffer) => $m10";
    if ($m10 != $forventet) {
	print " (forventet: $forventet)\n";
	print "not ";
    } else {
	print "\n";
    }
    print "ok $testno\n";
    $testno++;
}

print "Tester formattering av kontonummer...\n";
print "not " unless kontonr_f("5205 06 03512") eq "5205.06.03512";
print "ok $testno\n"; $testno++;

print "not " unless kontonr_f("1694801") eq "0000.16.94801";
print "ok $testno\n"; $testno++;

print "not " unless kontonr_f("") eq "????.??.?????";
print "ok $testno\n"; $testno++;

print "Tester formatering av kronebeløp...\n";
print "not " unless nok_f(3.5) eq "3,50";
print "ok $testno\n"; $testno++;

print "not " unless nok_f(3) eq "3,- ";
print "ok $testno\n"; $testno++;

print "not " unless nok_f(100) eq "100,- ";
print "ok $testno\n"; $testno++;

print "not " unless nok_f(49_998.50) eq "49.998,50";
print "ok $testno\n"; $testno++;

print "not " unless nok_f(1_000_000_000_000) eq "1.000.000.000.000,- ";
print "ok $testno\n"; $testno++;
