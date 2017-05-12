use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Statistics::DependantTTest',
    'VERSION_FROM'	=> 'DependantTTest.pm', # finds $VERSION
    'PREREQ_PM'		=> {Statistics::PointEstimation}, 
    'AUTHOR'            => 'Martin Lee <mlee@startechgroup.co.uk>',
    'ABSTRACT'          => 'Module to perform paired t-test',
    'PM' => { 'DependantTTest.pm' => '$(INST_LIBDIR)/DependantTTest.pm' }
);
