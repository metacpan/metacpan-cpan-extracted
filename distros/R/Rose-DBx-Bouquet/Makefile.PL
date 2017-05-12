use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
	 AUTHOR   => 'Ron Savage (ron@savage.net.au)',
	 ABSTRACT => 'Generate a set of Rose::DB::Object- and Rose::HTML::Form-based classes',
    ) : (),
	clean =>
	{
	 FILES => 'blib/* Makefile MANIFEST Rose-DBx-Bouquet-*'
	},
	dist =>
	{
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
	},
	DISTNAME  => 'Rose-DBx-Bouquet',
	NAME      => 'Rose::DBx::Bouquet',
	PL_FILES  => {},
	PREREQ_PM =>
	{
	 Carp             => 0,
	 Config::IniFiles => 0,
	 File::Path       => 0,
	 File::Spec       => 0,
	 Getopt::Long     => 0,
	 HTML::Template   => 0,
	 Pod::Usage       => 0,
	 Rose::DB         => 0,
	 Rose::DB::Object => 0,
	 Rose::HTML::Form => 0,
	},
	VERSION_FROM => 'lib/Rose/DBx/Bouquet.pm',
);
