use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %depends = (LWP::UserAgent => 2,
               HTTP::Request    => 0
               );



WriteMakefile(
    ABSTRACT		=> 'connect to the Qualys scanner API with perl',
    AUTHOR		=> 'Anthony G Persaud (apersaud@gmail.com)',
    clean		=> {FILES => "*.tar *.old pod2htm* *.htm*"},
    NAME		=> 'Qualys',
    PREREQ_PM		=> \%depends,
    VERSION_FROM	=> 'Qualys.pm' # finds $VERSION
	);

