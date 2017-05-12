use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Statistics::LogRank',
    'VERSION_FROM'	=> 'LogRank.pm', # finds $VERSION
    'PREREQ_PM'		=> {Statistics::Distributions}, 
    'AUTHOR'            => 'Martin Lee <mlee@startechgroup.co.uk>',
    'ABSTRACT'          => 'Module to perform log rank test',
    'PM' => { 'LogRank.pm' => '$(INST_LIBDIR)/LogRank.pm'}
);
