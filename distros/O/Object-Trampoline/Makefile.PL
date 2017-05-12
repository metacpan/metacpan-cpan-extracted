use v5.12;
use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME            => 'Object::Trampoline',
	VERSION_FROM	=> './lib/Object/Trampoline.pm',
	ABSTRACT_FROM   => './lib/Object/Trampoline.pm',

	PREREQ_PM =>
	{
        # take whatever versions are in the standard distro.

		qw
		(
			Carp            0
			Scalar::Util    0
			Symbol			0
		)
	},
);
