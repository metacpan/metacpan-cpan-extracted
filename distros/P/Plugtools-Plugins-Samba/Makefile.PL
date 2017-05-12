use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Plugtools::Plugins::Samba',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Plugtools/Plugins/Samba.pm',
			  ABSTRACT_FROM       => 'lib/Plugtools/Plugins/Samba.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'Plugtools'=>0,
							'Samba::SIDhelper'=>0,
							'Crypt::SmbHash'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Plugtools-Plugins-Samba-*' },
			  );
