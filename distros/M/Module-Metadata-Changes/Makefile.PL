use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Manage machine-readable Changes/CHANGES/Changelog.ini files',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Module-Metadata-Changes-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Module-Metadata-Changes',
	EXE_FILES => ['bin/ini.report.pl'],
	NAME      => 'Module::Metadata::Changes',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Config::IniFiles'				=> 2.88,
		'DateTime'						=> 0.66,
		'DateTime::Format::HTTP'		=> 0.42,
		'DateTime::Format::Strptime'	=> 1.73,
		'DateTime::Format::W3CDTF'		=> 0.06,
		'feature'						=> 0,
		'File::chdir'					=> 0.1010,
		'File::Slurper'					=> 0.008,
		'Getopt::Long'					=> 0,
		'HTML::Entities::Interpolate'	=> 1.06,
		'HTML::Template'				=> 2.95,
		'lib'							=> 0,
		'Moo'							=> 2.000002,
		'Pod::Usage'					=> 0,
		'strict'						=> 0,
		'Try::Tiny'						=> 0.24,
		'Types::Standard'				=> 1.000005,
		'version'						=> 0,
		'warnings'						=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::Pod'		=> 1.51,
		'Test::More'	=> 1.001002,
	},
	VERSION_FROM => 'lib/Module/Metadata/Changes.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'perl';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
		'version' => 2,
		},
		resources =>
		{
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Module::Metadata::Changes',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Module-Metadata-Changes.git',
				web		=> 'https://github.com/ronsavage/Module-Metadata-Changes',
			},
		},
	};
}

WriteMakefile(%params);

print "\a\n";
print "* Don't forget to install the CSS and *.tmpl files, which are \n";
print "* shipped in the htdocs/ directory within the distro, if you \n";
print "* wish to utilize the HTML output options of ini.report.pl. \n";
print "* Run ini.report.pl -h for details. \n";
print "\n";
