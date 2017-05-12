# Make symbolic links for fdmotd, fdquery, fdrip and fdsites
foreach my $prog (qw (fdmotd fdoggenc fdquery fdrip fdsites)) {
	my $prog_PL = $prog . '.PL';
	-f $prog_PL || symlink ('fdlscat.PL', $prog_PL);
}

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME'		=> 'Net::FreeDB2',
	'VERSION_FROM'	=> 'FreeDB2.pm', # finds $VERSION
	'PREREQ_PM'		=> {
		'Error' => 0,
		'HTTP::Request' => 0,
		'IO::Socket::INET' => 0,
		'LWP::UserAgent' => 0,
	},
	EXE_FILES => [
		qw (
			fdcdi
			fdlscat
			fdmotd
			fdoggenc
			fdquery
			fdrip
			fdsites
		)
	],
);

