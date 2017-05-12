package GCalTest;

sub get_calendar {
	my $how = shift;
	my $cal = Net::Google::Calendar->new();
	return &$how($cal);
}

sub login {
	my $cal = shift;
	die "we need GCAL_TEST_USER and GCAL_TEST_PASS env variables\n" 
		unless defined $ENV{GCAL_TEST_USER} && defined $ENV{GCAL_TEST_PASS};

	$cal->login($ENV{GCAL_TEST_USER}, $ENV{GCAL_TEST_PASS})
		or die "Couldn't login: $@\n";
	return $cal;
}


sub magic {
	die "we need GCAL_TEST_MAGIC_URL env variables\n" 
		unless defined $ENV{GCAL_TEST_MAGIC_URL};
	return Net::Google::Calendar->new( url => $ENV{GCAL_TEST_MAGIC_URL} );

}

sub authsub {
	my $cal = shift;
	die "we need GCAL_TEST_USER and GCAL_TEST_AUTH_TOKEN env variables\n" 
		unless defined $ENV{GCAL_TEST_USER} && defined $ENV{GCAL_TEST_AUTH_TOKEN};	
	$cal->auth($ENV{GCAL_TEST_USER}, $ENV{GCAL_TEST_AUTH_TOKEN}) 
		or die "Couldn't authenticate: $@\n";
	return $cal;
}


1;
