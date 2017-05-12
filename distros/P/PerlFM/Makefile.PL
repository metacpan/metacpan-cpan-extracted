use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'PerlFM',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/PerlFM.pm',
			  ABSTRACT_FROM       => 'lib/PerlFM.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Gtk2'=>0,
							'ZConf::Runner'=>0,
							'ZConf::Bookmarks'=>0,
							'Gtk2::PathButtonBar'=>0,
							'Gtk2::SimpleList'=>0,
							'Gtk2::Chmod'=>0,
							'Cwd'=>0,
							'File::Stat::Bits'=>0,
							'String::ShellQuote'=>0,
							'Test::More'=>0,
							'File::MimeInfo::Magic'=>0,
							'Dir::Watch'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'PerlFM-*' },
			  );
