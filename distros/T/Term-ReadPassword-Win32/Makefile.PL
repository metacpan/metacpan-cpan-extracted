use strict;
use warnings;

use ExtUtils::MakeMaker;
my %prereqs;
if ($^O eq 'MSWin32') {
	%prereqs = (
		'Win32'          => 0,
		'Win32::Console' => 0,
		'Win32API::File' => 0,
	);
} else {
	%prereqs = (
		'Term::ReadPassword' => 0,
	);
}


WriteMakefile(
	'NAME'         => 'Term::ReadPassword::Win32',
	'VERSION_FROM' => 'lib/Term/ReadPassword/Win32.pm',
	'LICENSE'      => 'perl',
	'PREREQ_PM'    => {
		'Test::More' => 0,
		%prereqs,
	},
	'META_MERGE'   => {
		resources => {
			repository  =>  'https://github.com/szabgab/Term-ReadPassword-Win32',
		},
	},
);
