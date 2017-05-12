#!perl 

print "1..3\n";

if ( $] >= 5.005 ) {
	print "ok 1 - PITA does not support perl prior to 5.004\n";
} else {
	print "not ok 1 - PITA does not support perl prior to 5.004\n";
}

eval {
	require PITA::Test::Dummy::Perl5::MI;
};

if ( length($@) ) {
	print "not ok 2 - PITA::Test::Dummy::Perl5::MI loads ok\n";
} else {
	print "ok 2 - PITA::Test::Dummy::Perl5::MI loads ok\n";
}

my $v = $PITA::Test::Dummy::Perl5::MI::VERSION;
my $e = '0.77';
if ( $v eq $e ) {
	print "ok 3 - PITA::Test::Dummy::Perl5::MI has correct version ( '$v' eq '$e' )\n";
} else {
	print "not ok 3 - PITA::Test::Dummy::Perl5::MI has correct version ( '$v' ne '$e' )\n";
}

exit(0);
