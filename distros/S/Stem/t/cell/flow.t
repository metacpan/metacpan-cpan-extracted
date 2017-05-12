
unless ( eval { require Parse::RecDescent } ) {

	print "1..0 # Skip Parse::RecDescent is not installed\n" ;
	exit ;
}

exec qw( run_stem event_loop=perl test_flow) ;
