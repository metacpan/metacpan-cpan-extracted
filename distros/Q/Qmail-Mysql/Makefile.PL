use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Qmail::Mysql',
    'VERSION_FROM'	=> 'Mysql.pm', # finds $VERSION
    'PREREQ_PM'		=> {
						DBI	=> 0,
						DBD::mysql=> 0.0,
						File::Path,
						}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Mysql.pod', # retrieve abstract from module
       AUTHOR     => 'Emiliano Bruni <info@ebruni.it>') : ()),
);
