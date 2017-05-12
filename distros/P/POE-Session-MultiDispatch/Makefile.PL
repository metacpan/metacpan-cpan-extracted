use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POE::Session::MultiDispatch',
    'VERSION_FROM'	=> 'MultiDispatch.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'POE' => 0, 'Test::More' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MultiDispatch.pm', # retrieve abstract from module
       AUTHOR     => 'Casey West <casey@geeknest.com>') : ()),
);
