
use v5.24;
use ExtUtils::MakeMaker;

use Cwd				qw( abs_path 	);
use File::Basename	qw( dirname		);

my $test_d	= abs_path dirname $0;
my $work_d	= dirname $test_d;
my $temp_d	= "$work_d/tmp";

-e $temp_d 
or mkdir $temp_d => 02775
or die "Failed mkdir: '$temp_d', $!";

WriteMakefile
(
    qw
    (
        NAME            Parallel::Queue
        VERSION         v4.0.5
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
			Cwd				0
			File::Basename  0
			File::Temp      0
			FindBin         0 
			Symbol          0
			Scalar::Util    0
		)
    }
);

