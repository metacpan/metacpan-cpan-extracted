use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SAL',
    'VERSION_FROM'	=> 'SAL.pm', # finds $VERSION
    'PREREQ_PM'		=> {'DBD::SQLite' => undef, 'GD::Graph' => undef}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SAL.pm', # retrieve abstract from module
       AUTHOR     => 'Scott Elcomb <psema4@gmail.com>') : ()),
);
