use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Net::Fix::Checksum::XS',
	VERSION_FROM      => 'lib/Net/Fix/Checksum/XS.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
	PREREQ_PM         => {
		'Exporter'        => 0,
		'XSLoader'        => 0,
	}, # e.g., Module::Name => 1.1
	ABSTRACT_FROM     => 'lib/Net/Fix/Checksum/XS.pm', # retrieve abstract from module
	AUTHOR            => 'Thomas Guyot-Sionnest <tguyot@gmail.com>',
	LICENSE           => 'perl',
	LIBS              => [''], # e.g., '-lm'
	# You can override FIX_MAX_MSG_LENGTH here (default 4096, incl. last FIX separator
	# and C string delimiter \0). e.g., '-DFIX_MAX_MSG_LENGTH=10000'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	META_MERGE        => {
		'meta-spec'       => { version => 2 },
		resources         => {
			repository        => {
				type              => 'git',
				url               => 'https://github.com/dermoth/Net-Fix-Checksum-XS.git',
				web               => 'https://github.com/dermoth/Net-Fix-Checksum-XS',
			},
		},
	},
);
