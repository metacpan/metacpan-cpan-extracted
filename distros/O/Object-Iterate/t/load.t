use Test::More;

my @classes = qw(Object::Iterate Object::Iterate::Tester);

foreach my $class ( @classes ) {
	print "bail out! $class did not compile\n" unless use_ok( $class );
	}

done_testing();
