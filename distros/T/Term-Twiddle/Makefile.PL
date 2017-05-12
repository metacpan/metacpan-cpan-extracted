use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Term::Twiddle',
    'VERSION_FROM'	=> 'Twiddle.pm', # finds $VERSION
    'PREREQ_PM'		=> { Time::HiRes => 1.30 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Twiddle.pm', # retrieve abstract from module
       AUTHOR     => 'Scott Wiersdorf <scott@perlcode.org>') : ()),
);
