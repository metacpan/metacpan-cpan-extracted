use inc::Module::Install 0.91;

check_innosetup() if winlike;

all_from       'lib/Perl/Dist.pm';
requires_from  'lib/Perl/Dist/Inno.pm';
requires       'CPAN'                => '1.9301';
requires       'Win32::File::Object' => '0.01' if winlike;
test_requires  'Test::More'          => '0.86';
test_requires  'Test::Script'        => '1.03';
test_requires  'Test::LongString'    => '0.11';
install_script 'perldist';
install_share;

WriteAll;

# Look for Inno Setup
sub check_innosetup {
	print "Looking for Inno Setup 5... ";
	unless ( $ENV{PROGRAMFILES} and -d $ENV{PROGRAMFILES} ) {
		pexit("Failed to find the Program Files directory\n");
	}
	require File::Spec;
	my $innosetup_dir  = File::Spec->catdir( $ENV{PROGRAMFILES}, "Inno Setup 5" );
	my $innosetup_file = File::Spec->catfile( $innosetup_dir, 'Compil32.exe' );
	unless ( -d $innosetup_dir and -f $innosetup_file ) {
		pexit(
			"failed",
			"",
			"Failed to find an installation of Inno Setup 5",
			"Please install http://www.jrsoftware.org/download.php/is.exe",
		);
	}
	print "OK\n";
}

sub pexit {
	print( map { "$_\n" } ( @_, '' ) );
	exit(0);
}
