
unless ( eval { require Parse::RecDescent } ) {

	print "1..0 # Skip Parse::RecDescent is not installed\n" ;
	exit ;
}

print "\n$_ = $ENV{ $_ }\n" for qw( PATH PERL5LIB STEM_CONF_PATH ) ;

exec 'run_stem test_packet_io' ;
