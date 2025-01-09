use Test::More;

my @classes = qw(Polyglot);
foreach my $class ( @classes ) {
	use_ok $class or BAIL_OUT( "$class did not compile: @!" );
	}

done_testing();
