use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Test::AutoLoader',
    'VERSION_FROM'	=> 'AutoLoader.pm', # finds $VERSION
    'PREREQ_PM'		=> {Test::Builder=>0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'AutoLoader.pm', # retrieve abstract from module
       AUTHOR     => 'Ben Warfield <ben_warfield@nrgn.com>') : ()),
);
