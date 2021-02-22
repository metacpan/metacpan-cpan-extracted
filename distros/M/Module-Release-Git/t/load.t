use Test::More 1;

my @classes = qw(Module::Release::Git);

foreach my $class ( @classes ) {
	print "bail out! $class did not compile\n" unless use_ok( $class );
	}

done_testing();
