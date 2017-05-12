use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Term::Prompt',
    VERSION_FROM      => 'lib/Term/Prompt.pm', # finds $VERSION
    ## Not sure about versions on prereqs, but there was never any req before this
    ## so the 'default' should be safe.
    PREREQ_PM         => {'Text::Wrap' => 1.0,
			  'Term::ReadKey' => 1.0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Term/Prompt.pm', # retrieve abstract from module
       AUTHOR         => 'Matthew Persico <persicom@cpan.org>') : ()),
);
