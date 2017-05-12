use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR' => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Arrays as objects with lots of handy methods',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Set-Array-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Set-Array',
	NAME      => 'Set::Array',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
	 	attributes => 0.06,
		Carp       => 1.01,
		overload   => 1.01,
		strict     => 1.03,
		subs       => 1.00,
		Test::Deep => 0.108,
		Test::More=> 0.47,
#		Test::Pod  => 1.45, # Make it optional. See t/pod.t
		Try::Tiny  => 0.11,
		Want       => 0,
		warnings   => 1.03,
	},
	VERSION_FROM => 'lib/Set/Array.pm',
);
