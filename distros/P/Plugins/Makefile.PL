
require 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Plugins',
	DISTNAME	=> 'Plugins',
	VERSION_FROM	=> 'lib/Plugins.pm',
	dist		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
	PREREQ_PM	=> {
		'Carp'			=> 0,
		'UNIVERSAL'		=> 0,
		'Hash::Util'		=> 0,
		'File::Slurp'		=> 0,
	},
);

package MY;

sub postamble {
    <<'END_OF_POSTAMBLE';

pm_to_blib: README README-Style1 README-API

README: lib/Plugins.pod
	pod2text  lib/Plugins.pod >README

README-Style1: lib/Plugins/Style1.pod
	pod2text  lib/Plugins/Style1.pod >README-Style1

README-API: lib/Plugins/API.pod
	pod2text  lib/Plugins/API.pod >README-API

END_OF_POSTAMBLE
}
