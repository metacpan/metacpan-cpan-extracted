
use v5.24;
use ExtUtils::MakeMaker;

WriteMakefile
(
    qw
    (
        NAME            Parallel::Queue
        VERSION         v4.0.1
        ABSTRACT_FROM   lib/Parallel/Queue.pm
        LICENSE         perl
    )
  , AUTHOR    => 'Steven Lembark <lembark@wrkhors.com>',
  , PREREQ_PM =>
    {
        # take whatever versions are in the standard distro.

		qw
		(
			autodie         0
			mro::EVERY      0
			strict          0
			Carp            0
			File::Basename  0
			File::Temp      0
			FindBin         0 
			Symbol          0
			Scalar::Util    0
		)
    }
);

