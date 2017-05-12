use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MultiProcFactory',
    'VERSION_FROM'	=> 'lib/MultiProcFactory.pm', # finds $VERSION
    'PMLIBDIRS'	  => [ qw( lib/ ) ],
    'PREREQ_PM'		=> {
      'IPC::Shareable' => '0'
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/MultiProcFactory.pm', # retrieve abstract from module
       AUTHOR     => 'Aaron Dancygier <adancygier@bigfootinteractive.com>') : ()),
);
