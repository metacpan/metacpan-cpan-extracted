use 5.008005;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Check if Cluto (or more specifically 'vcluster') is present on the system.
system("which vcluster >& /dev/null") == 0 or die <<'EOM';
#########################
Cluto (A C distribution) is a pre-requisite for this module.
Please install Cluto and rerun Makefile.PL
Cluto can be downloaded from http://glaros.dtc.umn.edu/gkhome/cluto/cluto/download\n\n
#########################
EOM

WriteMakefile(
    NAME              => 'Statistics::Gap',
    VERSION	      => '0.09',
    VERSION_FROM      => 'lib/Statistics/Gap.pm',
	PREREQ_PM         => {'Algorithm::RandomMatrixGeneration' => '0.02',
					  'Math::BigFloat' => '1.44'},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Statistics/Gap.pm', # retrieve abstract from module
       AUTHOR         => 'Anagha Kulkarni <kulka020@d.umn.edu>, Ted Pedersen <tpederse@d.umn.edu>') : ()),
);

