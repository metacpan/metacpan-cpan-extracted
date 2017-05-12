#!perl 

print "1..2\n";

if ( $] >= 5.004 ) {
	print "ok 1 - PITA does not support perl prior to 5.004\n";
} else {
	print "not ok 1 - PITA does not support perl prior to 5.004\n";
}

eval {
	require PITA::Test::Dummy::Perl5::Build;
};

if ( length($@) ) {
	print "not ok 2 - PITA::Test::Dummy::Perl5::Build loads ok\n";
} else {
	print "ok 2 - PITA::Test::Dummy::Perl5::Build loads ok\n";
}
