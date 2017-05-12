use Test::More tests => 5;
BEGIN { use_ok('Palm') }

for( "Test.pdb", "Test\x04.pdb", "Test\x80.prc", "Test\xfe.pdb" ) {
	print "Trying $_...";
	my $n = Palm::mkpdbname( $_ );
	print $n,"\n";
	ok( $n =~ m/[\x21-\x73]/ );
}

1;
