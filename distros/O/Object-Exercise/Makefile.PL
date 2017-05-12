use v5.20;
use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME            => 'Object::Exercise',
	VERSION         => '3.02',
	ABSTRACT_FROM   => 'lib/Object/Exercise.pm',
	PREREQ_PM =>
	{
		# any version of these will be sufficient.

		map { ( $_ => 0 ) }
		qw
		(
			strict
			Symbol
			IO::Handle
			List::Util
			Scalar::Util

			Test::More
			Test::Deep

			File::Basename

			Pod::Usage
			Time::HiRes

			YAML::XS
		)
	}
);
