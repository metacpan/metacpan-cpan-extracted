
use v5.10;
use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'Parallel::Queue',
    AUTHOR          => 'Steven Lembark <lembark@wrkhors.com>',

    VERSION_FROM    => 'lib/Parallel/Queue.pm',
    ABSTRACT_FROM   => 'lib/Parallel/Queue.pm',

	PREREQ_PM =>
	{
        # take whatever versions are in the standard distro.

		strict          => 0,
		Carp            => 0,
        Symbol          => 0,
        Symbol          => 0,
        Scalar::Util    => 0,
	},

);

