use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SSN::Validate',
		'SIGN'		=> 1,
    'VERSION_FROM'	=> 'Validate.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Test::More' => 0.45}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Validate.pm', # retrieve abstract from module
       AUTHOR     => 'Kevin Meltzer <kmeltz@cpan.org>') : ()),
);
