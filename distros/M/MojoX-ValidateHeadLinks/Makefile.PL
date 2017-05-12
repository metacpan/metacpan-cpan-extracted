use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Ensure CSS and JS links in web pages point to real files',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MojoX-ValidateHeadLinks-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'MojoX-ValidateHeadLinks',
	NAME      => 'MojoX::ValidateHeadLinks',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		feature         => 1.20,
		Getopt::Long    => 2.38,
		Hash::FieldHash => 0.12,
		Log::Handler    => 0.75,
		Mojolicious     => 3.30,
		Pod::Usage      => 1.51,
		strict          => 1.03,
		Test::More    => 0.94,
#		Test::Pod       => 1.45, # Make it optional. See t/pod.t
		Try::Tiny       => 0.11,
		warnings        => 1.03,
	},
	VERSION_FROM => 'lib/MojoX/ValidateHeadLinks.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources   =>
		{
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MojoX-ValidateHeadLinks',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/MojoX-ValidateHeadLinks.git',
				web  => 'https://github.com/ronsavage/MojoX-ValidateHeadLinks',
			},
		},
	};
}

WriteMakefile(%params);
