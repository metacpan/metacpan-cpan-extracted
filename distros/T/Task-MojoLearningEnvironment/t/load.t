use Test::More;
 
my @classes = qw(Task::MojoLearningEnvironment);

foreach my $class ( @classes ) {
	BAILOUT() unless use_ok( $class );
	}

done_testing();
