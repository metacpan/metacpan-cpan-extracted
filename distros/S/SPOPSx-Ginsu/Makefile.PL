use ExtUtils::MakeMaker;

sub write_makefile {
	# See lib/ExtUtils/MakeMaker.pm for details of how to influence
	# the contents of the Makefile that is written.
	WriteMakefile(
		'NAME'			=> 'SPOPSx-Ginsu',
		'PREREQ_PM'		=> { SPOPS => 0.86 },
		'AUTHOR'		=> 'Ray Zimmerman <rz10@cornell.edu>',
		'ABSTRACT'		=> 'SPOPS eXtension for Generalized INheritance SUpport',
		'PMLIBDIRS'		=> [ 'SPOPSx' ],
# 		'MAN3PODS'		=> {},
		'VERSION_FROM'	=> 'SPOPSx/Ginsu.pm', # finds $VERSION
	);
}

my $conf_file = 't/my_dbi_conf.pm';

if ( -f $conf_file ) {
	my $ans = lc get_input( "It appears you already have a $conf_file file.\n" .
						'Would you like to use it?', 'Y');
	
	unless ($ans eq 'y') {
		eval{ unlink( $conf_file ) };
	}
}

unless ( -f $conf_file ) {
	my $DB_NAME = get_input( "Enter name of database for testing", 'GinsuTest');
	my $DB_USER = get_input( "Enter database username for testing", 'test');
	my $DB_PASS = get_input( "Enter database password for testing", '');

	open( CONF, "> $conf_file" ) || die "Cannot open $conf_file for writing! Error: $!";
	print CONF <<EOF;
## define database connection parameters
## (must 'use' this file before 'use'ing MyDBI)
\$MyDBI::DSN  = 'DBI:mysql:$DB_NAME;mysql_client_found_rows=0';
\$MyDBI::USER = '$DB_USER';
\$MyDBI::PASS = '$DB_PASS';

1;
EOF

	close CONF;
	chmod 0600, $conf_file;
	print "Created $conf_file with database connection parameters.\n";
}

write_makefile();

sub get_input {
	my ( $prompt, $default ) = @_;
	my $val;

	do {
		print $prompt . " [ " . (defined $default ? $default : 'no default') . " ] : ";
		$val = <STDIN>;
		chomp $val;
		$val = $default		if $val =~ /^\s*$/; 
	} until ( defined $val );

	($val) = $val =~ /^\s*(.*)\s*$/;

	return $val;
}
